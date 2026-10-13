"""Offscreen tests of shipped QML; PAM is mocked, Wayland is NOT simulated.

Run with unittest discovery in an environment with PySide6. Missing Qt is
reported as skipped, never as proof that the lockscreen runtime works.
"""
import os
from pathlib import Path
import re
import shutil
import tempfile
import unittest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
try:
    from PySide6.QtCore import QObject, QPointF, QPoint, QUrl, Qt
    from PySide6.QtGui import QColor, QGuiApplication, QImage
    from PySide6.QtQml import QQmlExpression
    from PySide6.QtQuick import QQuickView
    from PySide6.QtMultimedia import QVideoSink
    from PySide6.QtTest import QTest
    QT_ERROR = None
except ImportError as error:
    QT_ERROR = str(error)

REPO = Path(__file__).resolve().parents[1]


@unittest.skipIf(QT_ERROR is not None, f"Qt unavailable: {QT_ERROR}")
class LockQmlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication([])
        cls.temp = tempfile.TemporaryDirectory(prefix="marko-lock-test-")
        cls.root = Path(cls.temp.name)
        src = REPO / "assets/config/quickshell"
        shutil.copytree(src / "marko-lock", cls.root / "lock")
        shutil.copy(src / "marko-shell/Theme.qml", cls.root / "lock/Theme.qml")
        # Reproduce both generated color modules from the public defaults.
        source = (REPO / "theme/colors.nix").read_text()
        for group, filename in (("quickshell", "Colors.qml"), ("lockscreen", "LockColors.qml")):
            palette = source.split(f"{group} = {{", 1)[1].split("};", 1)[0]
            fields = re.findall(r'(\w+) = "([^"\n]+)";', palette)
            (cls.root / "lock" / filename).write_text(
                'pragma Singleton\nimport QtQuick\nQtObject {\n' +
                '\n'.join(f' readonly property color {name}: "{value}"' for name, value in fields) + '\n}\n'
            )
        pam = cls.root / "Quickshell/Services/Pam"
        pam.mkdir(parents=True)
        (pam / "qmldir").write_text("module Quickshell.Services.Pam\nPamContext 1.0 PamContext.qml\nPamResult 1.0 PamResult.qml\n")
        (pam / "PamResult.qml").write_text("import QtQuick\nQtObject { enum Result { Success, Failed, Error, MaxTries } }\n")
        (pam / "PamContext.qml").write_text('''import QtQuick
QtObject {
    property string config: ""
    property bool active: false
    property bool responseRequired: false
    property bool responseVisible: false
    property string message: ""
    property bool messageIsError: false
    property bool startAllowed: true
    property int starts: 0
    property int responses: 0
    signal pamMessage()
    signal completed(int result)
    function start() { starts++; active = startAllowed; return active; }
    function abort() { active = false; responseRequired = false; }
    function prompt(visible) {
        responseRequired = true; responseVisible = visible;
        message = visible ? "Visible prompt" : "Password:"; pamMessage();
    }
    function respond(value) { responses++; }
    function finish(result) { abort(); completed(result); }
}''')
        (cls.root / "harness.qml").write_text('''import QtQuick
import "lock"
Item {
    id: harness
    property string videoPath: ""
    property string snapshotPath: ""
    width: 960; height: 640
    property alias controller: state
    property alias first: primary
    property alias second: secondary
    LockController { id: state }
    LockView { id: primary; anchors.fill: parent; controller: state;
               wallpaperPath: harness.videoPath; snapshotPath: harness.snapshotPath }
    LockView { id: secondary; width: 960; height: 640; visible: false; controller: state }
}''')

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def setUp(self):
        self.openView()

    def openView(self, initial=None):
        if hasattr(self, "view"):
            self.view.close()
            self.view.deleteLater()
            self.app.processEvents()
        self.view = QQuickView()
        self.view.engine().addImportPath(str(self.root))
        if initial:
            self.view.setInitialProperties(initial)
        self.view.setSource(QUrl.fromLocalFile(str(self.root / "harness.qml")))
        self.assertEqual(self.view.status(), QQuickView.Ready, str(self.view.errors()))
        self.subject = self.view.rootObject()
        self.view.engine().rootContext().setContextProperty("subject", self.subject)
        self.view.show()
        QTest.qWait(20)

    def tearDown(self):
        self.view.close()
        self.view.deleteLater()
        self.app.processEvents()

    def js(self, expression):
        query = QQmlExpression(self.view.engine().rootContext(), self.subject, expression)
        value = query.evaluate()
        self.assertFalse(query.hasError(), query.error().toString())
        # PySide exposes evaluate's optional valueIsUndefined output as a tuple.
        return value[0] if isinstance(value, tuple) else value

    def secure(self):
        self.js("subject.controller.engage(); subject.controller.secured()")
        QTest.qWait(820)
        self.js("subject.controller.pam.prompt(false)")

    def test_no_auth_or_animation_before_compositor_ack(self):
        self.js("subject.controller.engage()")
        QTest.qWait(250)
        self.assertTrue(self.js("subject.controller.requested"))
        self.assertEqual(self.js("subject.controller.pam.starts"), 0)
        self.assertEqual(self.js("subject.controller.reveal"), 0)
        self.js("subject.controller.pam.finish(0)")
        self.assertTrue(self.js("subject.controller.requested"))

    def test_opening_has_three_separate_intervals(self):
        self.js("subject.controller.engage(); subject.controller.secured()")
        QTest.qWait(150)
        self.assertLess(self.js("subject.controller.reveal"), 1)
        QTest.qWait(260)
        self.assertGreater(self.js("subject.controller.reveal"), 1)
        self.assertLess(self.js("subject.controller.reveal"), 2)
        QTest.qWait(260)
        self.assertGreater(self.js("subject.controller.reveal"), 2)
        QTest.qWait(170)
        self.assertAlmostEqual(self.js("subject.controller.reveal"), 3)
        self.assertTrue(self.js("subject.controller.requested"))

    def test_frozen_frame_slides_in_and_reverses_without_early_unlock(self):
        snapshot = self.root / "desktop % # frame.png"
        frame = QImage(96, 64, QImage.Format_RGB32)
        frame.fill(QColor("#f0275d"))
        self.assertTrue(frame.save(str(snapshot)))
        self.openView({"snapshotPath": str(snapshot)})
        frozen = self.subject.findChildren(QObject, "frozenDesktop")[0]
        scene = self.subject.findChildren(QObject, "lockScene")[0]
        self.js("subject.controller.engage()")
        self.assertTrue(frozen.property("visible"))
        self.assertAlmostEqual(frozen.x(), 0, delta=1)
        travel = 960 * 0.70 + 32
        self.assertAlmostEqual(scene.x(), travel, delta=1)
        self.assertAlmostEqual(scene.opacity(), 0, delta=0.001)
        self.js("subject.controller.reveal = 1")
        self.assertAlmostEqual(frozen.x(), 0, delta=1)
        self.assertAlmostEqual(frozen.scale(), 0.70, delta=0.001)
        self.assertAlmostEqual(scene.x(), travel, delta=1)
        self.js("subject.controller.reveal = 1.5")
        self.assertAlmostEqual(frozen.x(), -travel / 2, delta=2)
        self.assertAlmostEqual(scene.x(), travel / 2, delta=2)
        self.assertAlmostEqual(scene.scale(), 0.70, delta=0.001)
        self.js("subject.controller.reveal = 2")
        self.assertAlmostEqual(scene.x(), 0, delta=1)
        self.assertAlmostEqual(scene.scale(), 0.70, delta=0.001)
        self.js("subject.controller.reveal = 3")
        self.assertAlmostEqual(scene.scale(), 1, delta=0.001)
        self.js("subject.controller.reveal = 0")
        self.js("subject.controller.secured()")
        QTest.qWait(820)
        self.assertAlmostEqual(scene.x(), 0, delta=2)
        self.js("subject.controller.pam.finish(0)")
        QTest.qWait(350)
        self.assertTrue(self.js("subject.controller.requested"))
        self.assertGreater(scene.x(), 0)
        self.assertTrue(frozen.property("visible"))
        QTest.qWait(390)
        self.assertFalse(self.js("subject.controller.requested"))

    def test_success_releases_only_after_exit_animation(self):
        self.secure()
        self.js("subject.controller.pam.finish(0)")
        self.assertTrue(self.js("subject.controller.requested"))
        QTest.qWait(60)
        self.assertTrue(self.js("subject.controller.requested"))
        QTest.qWait(670)
        self.assertFalse(self.js("subject.controller.requested"))

    def test_failures_and_prompt_response_serialization(self):
        self.secure()
        self.js("subject.controller.respond('test'); subject.controller.respond('test')")
        self.assertEqual(self.js("subject.controller.pam.responses"), 1)
        self.js("subject.controller.pam.finish(1)")
        self.assertTrue(self.js("subject.controller.requested"))
        QTest.qWait(1150)
        self.assertEqual(self.js("subject.controller.pam.starts"), 2)
        self.js("subject.controller.pam.prompt(true)")
        self.assertTrue(self.js("subject.controller.responseVisible"))
        self.assertTrue(self.js("subject.controller.canRespond"))

    def test_pam_errors_never_release_and_maxtries_blocks_retry(self):
        self.secure()
        self.js("subject.controller.pam.finish(2)")
        self.assertTrue(self.js("subject.controller.requested"))
        self.assertTrue(self.js("subject.controller.canRetry"))
        self.js("subject.controller.beginAuthentication(); subject.controller.pam.finish(3)")
        starts = self.js("subject.controller.pam.starts")
        self.js("subject.controller.beginAuthentication()")
        QTest.qWait(1150)
        self.assertEqual(self.js("subject.controller.pam.starts"), starts)
        self.assertFalse(self.js("subject.controller.canRetry"))
        self.assertTrue(self.js("subject.controller.requested"))

    def test_start_failure_and_lock_loss_clear_authentication(self):
        self.js("subject.controller.pam.startAllowed = false")
        self.js("subject.controller.engage(); subject.controller.secured()")
        QTest.qWait(230)
        self.assertTrue(self.js("subject.controller.statusError"))
        self.assertTrue(self.js("subject.controller.requested"))
        self.js("subject.controller.lockLost()")
        self.assertFalse(self.js("subject.controller.authenticated"))
        self.assertFalse(self.js("subject.controller.pam.active"))
        self.assertEqual(self.js("subject.controller.phase"), "idle")

    def test_new_request_cancels_authenticated_exit(self):
        self.secure()
        self.js("subject.controller.pam.finish(0)")
        QTest.qWait(40)
        self.js("subject.controller.engage()")
        QTest.qWait(250)
        self.assertTrue(self.js("subject.controller.requested"))
        self.assertFalse(self.js("subject.controller.authenticated"))
        self.assertEqual(self.js("subject.controller.pam.starts"), 2)

    def test_keyboard_escape_and_all_views_clear(self):
        self.secure()
        inputs = self.subject.findChildren(QObject, "lockResponse")
        self.assertEqual(len(inputs), 2)
        # QML input objects can receive focus and Qt keyboard events offscreen.
        primary = inputs[0]
        primary.forceActiveFocus()
        QTest.keyClick(self.view, Qt.Key_A)
        self.assertEqual(primary.property("text"), "a")
        QTest.keyClick(self.view, Qt.Key_Escape)
        self.assertEqual(primary.property("text"), "")
        self.assertTrue(self.js("subject.controller.requested"))
        for field in inputs:
            field.setProperty("text", "test")
        QTest.keyClick(self.view, Qt.Key_Return)
        self.assertTrue(all(field.property("text") == "" for field in inputs))
        self.assertEqual(self.js("subject.controller.pam.responses"), 1)

    def test_button_and_outside_click(self):
        self.secure()
        QTest.mouseClick(self.view, Qt.LeftButton, Qt.NoModifier, QPoint(10, 10))
        self.assertTrue(self.js("subject.controller.requested"))
        inputs = self.subject.findChildren(QObject, "lockResponse")
        inputs[0].setProperty("text", "test")
        button = self.subject.findChildren(QObject, "lockSubmit")[0]
        point = button.mapToScene(QPointF(button.width() / 2, button.height() / 2)).toPoint()
        QTest.mouseClick(self.view, Qt.LeftButton, Qt.NoModifier, point)
        self.assertEqual(self.js("subject.controller.pam.responses"), 1)
        self.assertTrue(self.js("subject.controller.requested"))
        self.assertEqual(inputs[0].property("text"), "")

    def test_real_video_frames_and_file_url_escaping(self):
        # Synthetic 64x48 MPEG-4 fixture: 20 grayscale frames, no audio.
        sample = self.root / "clip % # quote'.mp4"
        shutil.copy(REPO / "tests/fixtures/lock-motion.mp4", sample)
        self.openView({"videoPath": str(sample)})
        self.secure()
        output = self.subject.findChildren(QObject, "wallpaperOutput")[0]
        sink = output.property("videoSink")
        timestamps = []
        sink.videoFrameChanged.connect(
            lambda frame: timestamps.append(frame.startTime()) if frame.isValid() else None
        )
        QTest.qWait(700)
        self.assertGreaterEqual(len(set(timestamps)), 2, "No advancing decoded video frames")
        self.assertTrue(self.js("subject.controller.requested"))

    def test_bad_video_keeps_authentication_usable(self):
        self.openView({"videoPath": str(self.root / "missing.mp4")})
        self.secure()
        QTest.qWait(150)
        wallpaper = self.subject.findChildren(QObject, "lockWallpaper")[0]
        self.assertTrue(wallpaper.property("failed"))
        self.assertTrue(self.js("subject.controller.canRespond"))
        self.assertTrue(self.js("subject.controller.requested"))

    def test_duplicate_lock_is_idempotent_and_render(self):
        self.secure()
        self.js("subject.controller.engage(); subject.controller.engage()")
        self.assertEqual(self.js("subject.controller.pam.starts"), 1)
        self.assertAlmostEqual(self.js("subject.controller.reveal"), 3)
        image = self.view.grabWindow()
        self.assertFalse(image.isNull())
        if path := os.environ.get("MARKO_LOCK_TEST_SCREENSHOT"):
            self.assertTrue(image.save(path))


if __name__ == "__main__":
    unittest.main()

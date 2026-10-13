# Keep the bar on its existing package; only the locker needs these bug fixes.
{ pkgs }:
pkgs.quickshell.overrideAttrs (old: {
  version = "0.3.2";
  src = pkgs.fetchurl {
    url = "https://codeload.github.com/quickshell-mirror/quickshell/tar.gz/refs/tags/v0.3.2";
    name = "quickshell-0.3.2.tar.gz";
    hash = "sha256-lGon4qJ2kXoDwQeeXGCXGvhOznMIjDZh3uRV2S60IPc=";
  };
  # wrapQtAppsHook discovers the Multimedia QML plugin from buildInputs.
  buildInputs = old.buildInputs ++ [ pkgs.qt6.qtmultimedia ];
  cmakeFlags = builtins.filter
    (flag: !(pkgs.lib.hasInfix "GIT_REVISION" flag)) old.cmakeFlags
    ++ [ (pkgs.lib.cmakeFeature "GIT_REVISION" "tag-v0.3.2") ];
})

{ config, pkgs, lib, markoTheme, ... }:
let
  cfg = config.programs.markoLock;
  quickshell = import ../packages/lock-quickshell.nix { inherit pkgs; };
  daemon = pkgs.writeShellScriptBin "marko-lock-daemon" ''
    set -eu
    export QT_QPA_PLATFORM=wayland
    export QS_DISABLE_FILE_WATCHER=1
    export QS_DISABLE_CRASH_HANDLER=1
    export MARKO_LOCK_FALLBACK=${lib.escapeShellArg "${config.xdg.dataHome}/wallpapers/desktop.jpg"}
    export MARKO_LOCK_CAPTURE_DIR="''${XDG_RUNTIME_DIR:?}/marko-lock-capture"
    export MARKO_LOCK_CLEANUP_BIN=${lib.escapeShellArg "${pkgs.coreutils}/bin/rm"}
    wallpaper=${lib.escapeShellArg cfg.wallpaperPath}
    if [ -n "$wallpaper" ] && [ -r "$wallpaper" ]; then
      export MARKO_LOCK_WALLPAPER="$wallpaper"
    else
      export MARKO_LOCK_WALLPAPER="$MARKO_LOCK_FALLBACK"
    fi
    exec ${quickshell}/bin/qs -c marko-lock --no-duplicate --daemonize
  '';
  launcher = pkgs.writeShellScriptBin "marko-lock" ''
    set -eu
    umask 077
    # Serialize requests, including repeated shortcut presses and cold starts.
    exec 9>"''${XDG_RUNTIME_DIR:?}/marko-lock-launch.lock"
    ${pkgs.util-linux}/bin/flock --exclusive --wait 30 9 || exit 1
    ipc() {
      ${pkgs.coreutils}/bin/timeout 1 ${quickshell}/bin/qs ipc -c marko-lock call lock "$@" 9>&-
    }
    show_logs() {
      ${pkgs.coreutils}/bin/timeout 2 ${quickshell}/bin/qs log -c marko-lock -t 40 9>&- >&2 || true
    }
    # QuickShell writes "No running instances" to stdout. Trust the IPC
    # response only when the command succeeds and returns a boolean.
    state="$(ipc isSecure 2>/dev/null)" || state=""
    case "$state" in
      true) exit 0 ;;
      false) ;;
      *) state="" ;;
    esac
    # Warm the locker before capture, so cold QML startup does not age the
    # desktop frame. Only the actual lock request follows the screenshots.
    if [ -z "$state" ]; then
      # QuickShell's --daemonize parent reports only after the child loads QML.
      # The first load can exceed five seconds on a cold system.
      if ${pkgs.coreutils}/bin/timeout 15 ${daemon}/bin/marko-lock-daemon 9>&-; then
        :
      else
        status=$?
        printf 'marko-lock: daemon startup failed (exit %s)\n' "$status" >&2
        show_logs
        exit 1
      fi
    fi
    deadline=$((SECONDS + 5))
    while [ "$SECONDS" -lt "$deadline" ]; do
      [ "$(ipc isSecure 2>/dev/null || true)" = "true" ] && exit 0
      [ "$(ipc isReady 2>/dev/null || true)" = "true" ] && break
      ${pkgs.coreutils}/bin/sleep 0.1
    done
    if [ "$(ipc isReady 2>/dev/null || true)" != "true" ]; then
      printf '%s\n' 'marko-lock: lock instance did not become ready' >&2
      show_logs
      exit 1
    fi
    capture_dir="''${XDG_RUNTIME_DIR:?}/marko-lock-capture"
    # Screenshots stay under the user's private runtime directory. A previous
    # crashed instance may have left files here, so clear them before capture.
    ${pkgs.coreutils}/bin/rm -rf -- "$capture_dir"
    ${pkgs.coreutils}/bin/mkdir -m 700 -- "$capture_dir"
    captured=0
    if outputs="$(${pkgs.coreutils}/bin/timeout 1 ${pkgs.niri}/bin/niri msg --json outputs 2>/dev/null)"; then
      while IFS= read -r output; do
        [ -n "$output" ] || continue
        if ${pkgs.coreutils}/bin/timeout 2 ${pkgs.grim}/bin/grim -o "$output" -t png -l 1 \
          "$capture_dir/$output.png" 9>&- >/dev/null 2>&1; then
          captured=$((captured + 1))
        else
          ${pkgs.coreutils}/bin/rm -f -- "$capture_dir/$output.png"
          printf 'marko-lock: desktop capture failed for %s\n' "$output" >&2
        fi
      done < <(printf '%s' "$outputs" | ${pkgs.jq}/bin/jq -r \
        'to_entries[] | select(.value.logical != null) | .key | select(test("^[A-Za-z0-9._-]+$"))')
    fi
    if [ "$captured" -eq 0 ]; then
      printf '%s\n' 'marko-lock: no desktop capture; zoom-out stage will use the opaque fallback' >&2
    fi
    ipc engage >/dev/null 2>&1 || true
    deadline=$((SECONDS + 3))
    while [ "$SECONDS" -lt "$deadline" ]; do
      if [ "$(ipc isSecure 2>/dev/null || true)" = "true" ]; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done
    # Do not report success without the compositor's secure acknowledgement.
    # If Niri is already locked, it retains its locked background on failure.
    ${pkgs.coreutils}/bin/rm -rf -- "$capture_dir"
    printf '%s\n' 'marko-lock: no secure acknowledgement; check the lock instance from a TTY' >&2
    exit 1
  '';
in
{
  options.programs.markoLock = {
    wallpaperPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Resolved shared wallpaper path; supplied by desktop-environment.nix.";
    };
  };

  config = {
    home.packages = [ launcher daemon ];
    xdg.configFile = {
      "quickshell/marko-lock" = {
        source = ../assets/config/quickshell/marko-lock;
        recursive = true;
      };
      "quickshell/marko-lock/Theme.qml".source = ../assets/config/quickshell/marko-shell/Theme.qml;
      "quickshell/marko-lock/Colors.qml".source = markoTheme.quickshellColors;
      "quickshell/marko-lock/LockColors.qml".source = markoTheme.lockscreenColors;
    };
  };
}

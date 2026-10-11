{ pkgs, lib, inputs, ... }:

let
  wallpaperSettingsFile = "${inputs.private-config}/wallpaper/settings.json";
  wallpaperSettings =
    if builtins.pathExists wallpaperSettingsFile then
      builtins.fromJSON (builtins.readFile wallpaperSettingsFile)
    else
      { enable = false; path = ""; };
  wallpaperPath =
    if builtins.isString (wallpaperSettings.path or null) then
      wallpaperSettings.path
    else
      "";
  validWallpaperPath =
    wallpaperPath != ""
    && (lib.hasPrefix "/" wallpaperPath
      || (!lib.hasPrefix "~" wallpaperPath
        && !(lib.elem ".." (lib.splitString "/" wallpaperPath))));
  configuredWallpaper =
    if (wallpaperSettings.enable or false) && validWallpaperPath then
      if lib.hasPrefix "/" wallpaperPath then
        wallpaperPath
      else
        "${inputs.private-config}/${wallpaperPath}"
    else
      "";
  wallpaperLauncher = pkgs.writeShellScriptBin "marko-wallpaper" ''
    default_wallpaper="''${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/desktop.jpg"
    configured_wallpaper=${lib.escapeShellArg configuredWallpaper}
    if [ -n "$configured_wallpaper" ] && [ -f "$configured_wallpaper" ]; then
      wallpaper="$configured_wallpaper"
    else
      if [ -n "$configured_wallpaper" ]; then
        printf 'marko-wallpaper: configured file missing: %s; using default\n' "$configured_wallpaper" >&2
      fi
      wallpaper="$default_wallpaper"
    fi
    exec ${pkgs.mpvpaper}/bin/mpvpaper -o 'no-audio loop-file=inf image-display-duration=inf keepaspect=yes video-unscaled=no video-aspect-override=no video-zoom=0 video-scale-x=1 video-scale-y=1 panscan=1 video-align-x=0 video-align-y=0 video-pan-x=0 video-pan-y=0' ALL "$wallpaper"
  '';
  markoShell = pkgs.runCommandLocal "marko-shell" {
    nativeBuildInputs = [ pkgs.qt6.qtshadertools ];
  } ''
    mkdir -p "$out"
    cp -r ${../assets/config/quickshell/marko-shell}/. "$out/"
    qsb --glsl "300es,330" \
      -o "$out/SdfPopup.frag.qsb" "$out/SdfPopup.frag"
  '';
in
{
  assertions = [
    {
      assertion = !(wallpaperSettings.enable or false) || validWallpaperPath;
      message = "private-config/wallpaper/settings.json: enabled wallpaper path must be absolute or relative to private-config without '..' or '~'.";
    }
  ];
  home.packages = [ wallpaperLauncher ];
  xdg.dataFile."wallpapers/desktop.jpg".source =
    ../assets/wallpapers/148557481_p1.jpg;
  # Fcitx also looks in the user's XDG data directory. Keep the theme visible
  # when the running daemon did not inherit the fcitx5-with-addons wrapper path.
  xdg.dataFile."fcitx5/themes/marko-shell".source =
    ../assets/config/fcitx5/marko-shell;

  # Config
  xdg.configFile."niri/config.kdl".source = ../assets/config/niri/config.kdl;
  xdg.configFile."kitty/kitty.conf".source = ../assets/config/kitty/kitty.conf;
  xdg.configFile."wofi/config".source = ../assets/config/wofi/config;
  xdg.configFile."wofi/style.css".source = ../assets/config/wofi/style.css;
  xdg.configFile."mako/config".source = ../assets/config/mako/config;
  xdg.configFile."quickshell/marko-shell" = {
    source = markoShell;
    recursive = true;
  };
}

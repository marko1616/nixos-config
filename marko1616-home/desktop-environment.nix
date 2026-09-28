{ pkgs, ... }:

let
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
  xdg.dataFile."wallpapers/desktop.png".source =
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

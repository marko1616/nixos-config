{ ... }:
{
  xdg.dataFile."wallpapers/desktop.png".source =
    ../assets/wallpapers/148557481_p1.jpg;

  # Config
  xdg.configFile."niri/config.kdl".source = ../assets/config/niri/config.kdl;
  xdg.configFile."kitty/kitty.conf".source = ../assets/config/kitty/kitty.conf;
  xdg.configFile."wofi/config".source = ../assets/config/wofi/config;
  xdg.configFile."wofi/style.css".source = ../assets/config/wofi/style.css;
  xdg.configFile."mako/config".source = ../assets/config/mako/config;
  xdg.configFile."quickshell/marko-shell" = {
    source = ../assets/config/quickshell/marko-shell;
    recursive = true;
  };
}

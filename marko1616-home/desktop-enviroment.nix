{ ... }:
{
  xdg.dataFile."wallpapers/desktop.png".source =
    ../assets/wallpapers/148557481_p1.jpg;

  # Config
  xdg.configFile."niri/config.kdl".source = ../assets/config/niri/config.kdl;
  xdg.configFile."kitty/kitty.conf".source = ../assets/config/kitty/kitty.conf;
  xdg.configFile."waybar/config".source = ../assets/config/waybar/config;
  xdg.configFile."waybar/style.css".source = ../assets/config/waybar/style.css;
  xdg.configFile."wofi/config".source = ../assets/config/wofi/config;
  xdg.configFile."wofi/style.css".source = ../assets/config/wofi/style.css;
  xdg.configFile."mako/config".source = ../assets/config/mako/config;
  xdg.configFile."networkmanager-dmenu/config.ini".source = ../assets/config/networkmanager-dmenu/config.ini;
}

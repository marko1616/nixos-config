{ config, pkgs, ... }:
{
  imports = [  ];

  # Basic stuff
  home.username = "marko1616";
  home.homeDirectory = "/home/marko1616";

  home.stateVersion = "26.05";

  # Niri utils
  programs.kitty.enable = true;
  programs.fuzzel.enable = true;
  programs.waybar.enable = true;
  programs.swaylock.enable = true;

  services.mako.enable = true;
  services.swayidle.enable = true;

  # Packages
  home.packages = with pkgs; [
    v2rayn
    awww
    xwayland-satellite
    wl-clipboard
  ];

  # Config files
  xdg.configFile."niri/config.kdl".source = ../assets/config/niri/config.kdl;
  xdg.configFile."kitty/kitty.conf".source = ../assets/config/kitty/kitty.conf;
  xdg.configFile."waybar/config".source = ../assets/config/waybar/config;
  xdg.configFile."waybar/style.css".source = ../assets/config/waybar/style.css;
  xdg.configFile."fuzzel/fuzzel.ini".source = ../assets/config/fuzzel/fuzzel.ini;
  xdg.configFile."btop/btop.conf".source = ../assets/config/btop/btop.conf;
}

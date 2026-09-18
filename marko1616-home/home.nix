{ config, pkgs, ... }:
{
  imports = [ ./desktop-enviroment.nix ./zsh.nix ./btop.nix ./nvim.nix ./python.nix ./llvm-toolchain.nix ./qq.nix ];

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
}

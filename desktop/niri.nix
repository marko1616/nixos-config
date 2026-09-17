{ config, pkgs, ...}:
{
  programs.niri.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
}

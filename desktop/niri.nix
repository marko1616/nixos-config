{ config, pkgs, ...}:
{
  programs.niri.enable = true;
  services.displayManager.sddm = {
    enable = true;
    theme = "pixie";
    # Crucial for Qt6: Use the KDE/Qt6 build of SDDM to fix missing cursors and module errors
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;

    # Fix for NixOS explicitly requiring a cursor theme
    settings = {
      Theme = {
        CursorTheme = "breeze_cursors"; # Change this if you use a different cursor theme (e.g., Adwaita)
      };
    };
  };
}

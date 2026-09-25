{ config, pkgs, ...}:
{
  programs.niri.enable = true;
  services.displayManager.sddm = {
    enable = true;
    theme = "pixie";
    # Crucial for Qt6: Use the KDE/Qt6 build of SDDM to fix missing cursors and module errors
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
    extraPackages = with pkgs.kdePackages; [ qtsvg qtdeclarative qt5compat ];

    # Fix for NixOS explicitly requiring a cursor theme
    settings = {
      # Make sure changes will apply
      General.GreeterEnvironment = "QML_DISABLE_DISK_CACHE=1";
      Theme = {
        CursorTheme = "breeze_cursors"; # Change this if you use a different cursor theme (e.g., Adwaita)
      };
    };
  };
}

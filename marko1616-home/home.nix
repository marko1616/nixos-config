{ config, pkgs, ... }:
{
  imports = [ ./desktop-environment.nix ./zsh.nix ./btop.nix ./nvim.nix ./python.nix ./llvm-toolchain.nix ./qq.nix ];

  # Niri utils
  programs.kitty.enable = true;
  programs.wofi.enable = true;
  programs.swaylock.enable = true;

  services.mako.enable = true;
  services.swayidle.enable = true;

  # Packages
  home.packages = with pkgs; [
    v2rayn
    awww
    xwayland-satellite
    wl-clipboard
    quickshell
    iw # Supplies the kernel association query used by the QuickShell Wi-Fi panel.
    networkmanagerapplet # Provides nm-connection-editor for Advanced settings.
  ];
}

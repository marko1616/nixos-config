{ config, pkgs, lib, markoTheme, ... }:
let
  # swaylock accepts rrggbb[aa], while the shared palette uses #rrggbb[aa].
  lockColor = value: lib.removePrefix "#" value;
  lock = markoTheme.colors.swaylock;
in
{
  imports = [ ./desktop-environment.nix ./zsh.nix ./btop.nix ./nvim.nix ./python.nix ./llvm-toolchain.nix ./qq.nix ];

  # Niri utils
  programs.kitty.enable = true;
  programs.wofi.enable = true;
  programs.swaylock = {
    enable = true;
    settings = {
      color = lockColor lock.background;
      font = "Sans";
      font-size = 22;
      indicator-idle-visible = true;
      indicator-radius = 110;
      indicator-thickness = 8;
      show-failed-attempts = true;
      show-keyboard-layout = true;
      inside-color = lockColor lock.inside;
      inside-clear-color = lockColor lock.insideClear;
      inside-ver-color = lockColor lock.insideVerifying;
      inside-wrong-color = lockColor lock.insideWrong;
      ring-color = lockColor lock.ring;
      ring-clear-color = lockColor lock.ringClear;
      ring-ver-color = lockColor lock.ringVerifying;
      ring-wrong-color = lockColor lock.ringWrong;
      line-color = lockColor lock.line;
      line-clear-color = lockColor lock.line;
      line-ver-color = lockColor lock.line;
      line-wrong-color = lockColor lock.line;
      text-color = lockColor lock.text;
      text-clear-color = lockColor lock.textClear;
      text-ver-color = lockColor lock.textVerifying;
      text-wrong-color = lockColor lock.textWrong;
      key-hl-color = lockColor lock.keyHighlight;
      bs-hl-color = lockColor lock.backspaceHighlight;
      separator-color = lockColor lock.separator;
      layout-bg-color = lockColor lock.layoutBackground;
      layout-border-color = lockColor lock.layoutBorder;
      layout-text-color = lockColor lock.layoutText;
    };
  };

  services.mako.enable = true;
  services.swayidle.enable = true;

  # Packages
  home.packages = with pkgs; [
    v2rayn
    mpvpaper
    xwayland-satellite
    wl-clipboard
    quickshell
    networkmanager # nmcli supplies cached AP/BSSID scan results for the shell.
    (writeShellScriptBin "marko-wifi-connect" ''
      exec ${python3.withPackages (ps: [ ps.dbus-next ])}/bin/python3 ${../scripts/marko_wifi_connect.py}
    '')
    networkmanagerapplet # Provides nm-connection-editor for Advanced settings.
    moonlight-qt
    wireshark
    google-chrome
    libreoffice
  ];
}

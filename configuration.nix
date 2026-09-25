# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:
let
  sddm-theme = pkgs.callPackage ./desktop/sddm-theme.nix { inherit inputs; };
in
{
  imports =
    [
      ./desktop/niri.nix
      ./desktop/sddm-avatars.nix
      ./services/ssh.nix
    ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.sharedModules = [ ./marko1616-home/home.nix ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.terminess-ttf
  ];

  # Install firefox.
  programs.firefox.enable = true;

  # Install steam.
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    unzip
    zsh
    file
    xxd
    neovim
    fastfetch
    nmap
    btop
    wget
    git
    curl
    tmux
    appimage-run
    sddm-theme
    libnotify # For testing notify system
    kdePackages.qtdeclarative
    kdePackages.qtsvg
    kdePackages.qt5compat # Included for wider QML component compatibility
    obs-studio
    vlc
  ];

  programs.zsh = {
    enable = true;
    # Oh My Zsh initializes completion through Home Manager.
    enableGlobalCompInit = false;
    # Oh My Zsh supplies the prompt.
    promptInit = "";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

}

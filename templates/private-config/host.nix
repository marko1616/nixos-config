{ pkgs, repoRoot, ... }:
let
  # Replace these examples in private/host.nix before the first build.
  username = "CHANGE_ME_USER";
  hostname = "CHANGE_ME_HOST";
in {
  imports = [ ./hardware-configuration.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostname;
  time.timeZone = "Asia/Hong_Kong";
  i18n.defaultLocale = "en_HK.UTF-8";
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # Match your existing boot loader and kernel; these are examples only.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  home-manager.users.${username} = {
    home.username = username;
    home.homeDirectory = "/home/${username}";
    # Preserve the existing value on the target machine.
    home.stateVersion = "26.05";
  };
  environment.etc."sddm-avatars/${username}.face.icon".source =
    repoRoot + "/assets/avatars/marko1616.png";

  # Preserve the existing value on the target machine.
  system.stateVersion = "26.05";
  assertions = [ {
    assertion = username != "CHANGE_ME_USER" && hostname != "CHANGE_ME_HOST";
    message = "Edit the username and host settings in private/host.nix first.";
  } ];
}

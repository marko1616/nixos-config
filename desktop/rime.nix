{ config, lib, pkgs, ... }:
let
  cfg = config.programs.markoInput;
  data = pkgs.callPackage ./rime-data.nix { };
in
{
  options.programs.markoInput.enable = lib.mkEnableOption "Flypy with U/V modes in Fcitx5";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod.fcitx5.addons = [
      (pkgs.fcitx5-rime.override { rimeDataPkgs = [ data ]; })
    ];
    # Defaults only: never replace an existing user's profile or Rime databases.
    i18n.inputMethod.fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "rime";
      };
      "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
      "Groups/0/Items/1" = { Name = "rime"; Layout = ""; };
      "Groups/0/Items/2" = { Name = "pinyin"; Layout = ""; };
    };
  };
}

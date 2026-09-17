{ config, ... }:
{
  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    enableCompletion = true;

    autosuggestion = {
      enable = true;
      highlight = "fg=#565f89";
    };

    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
    };

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
      ];

      custom = "${config.xdg.configHome}/oh-my-zsh/custom";
      theme = "fino";

      extraConfig = ''
        # Oh My Zsh is updated through NixOS.
        zstyle ':omz:update' mode disabled
      '';
    };

    initContent = ''
      source "${config.xdg.configHome}/zsh/greeting.zsh"
    '';
  };

  xdg.configFile = {
    "zsh/greeting.txt".source =
      ../assets/config/zsh/greeting.txt;
    "zsh/greeting.zsh".source =
      ../assets/config/zsh/greeting.zsh;
  };
}

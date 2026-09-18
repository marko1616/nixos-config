{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tree-sitter
  ];

  # Configs
  xdg.configFile."nvim".source =
    ../assets/config/nvim;

  xdg.dataFile."nvim/plugins".source =
    ../assets/plugins/nvim;
}

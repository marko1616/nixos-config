{ pkgs, markoTheme, ... }:
{
  home.packages = with pkgs; [
    tree-sitter
  ];

  # Configs
  xdg.configFile."nvim".source =
    markoTheme.neovim;

  xdg.dataFile."nvim/plugins".source =
    ../assets/plugins/nvim;
}

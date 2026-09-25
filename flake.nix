{
  description = "NixOS desktop with a separate private host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pixie-sddm = {
      url = "github:marko1616/pixie-sddm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private-config = {
      # Managed by cli.py private switch. No credentials in this URL.
      url = "path:./templates/private-config";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      cliPython = pkgs.python3.withPackages (ps: [
        ps.typer ps.questionary ps.rich
      ]);
    in {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; repoRoot = ./.; };
        modules = [
          home-manager.nixosModules.home-manager
          ./configuration.nix
          "${inputs.private-config}/host.nix"
        ];
      };
    };
}

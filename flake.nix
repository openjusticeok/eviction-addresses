{
  description = "eviction-addresses - R development shell";

  inputs = {
    opi-flakes.url = "github:openjusticeok/flakes";
    nixpkgs.follows = "opi-flakes/nixpkgs";
    flake-parts.follows = "opi-flakes/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, opi-flakes, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      imports = [ opi-flakes.flakeModules.opi ];

      perSystem = { pkgs, ... }: {
        opi.shells.default = {
          layers = [ "shiny" ];
          packages = with pkgs; [
            unixodbc
            libsodium
          ];
        };
      };
    };
}

{
  description = "Personal website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { flake-parts, treefmt-nix, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ treefmt-nix.flakeModule ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        let
        gems = pkgs.bundlerEnv {
          name = "jekyll-env";
          ruby = pkgs.ruby;
          gemset  = ./gemset.nix;
          gemfile  = ./Gemfile;
          lockfile  = ./Gemfile.lock;
        };
        buildSite = {pkgs, stdenv, ruby, ...}: stdenv.mkDerivation {
         name = "build-site";
         src = ./.;
         buildInputs = [ruby gems];
         installPhase = ''
           mkdir -p $out/bin
           echo "#!/usr/bin/env bash
           bundle exec jekyll build" > $out/bin/build-site
           chmod +x $out/bin/build-site
         '';
        };
        in {
          imports = [ ./nix/treefmt.nix ];

          packages.default = pkgs.callPackage buildSite {};
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              ruby
              jekyll
              act
              bundix
            ];
          };
        };
    };
}

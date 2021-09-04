# https://discourse.nixos.org/t/home-manager-installation-questions/7204/5
{ pkgs ? import <nixpkgs> { } }:
with pkgs;
{
  home-manager =
    let
      src = builtins.fetchGit {
        name = "home-manager";
        url = https://github.com/nix-community/home-manager;
        ref = "release-21.05";
      };

      # `path` is required for `home-manager` to find its own sources
    in
    callPackage "${src}/home-manager" { path = "${src}"; };
}

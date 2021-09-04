#1f6f0c9b3a832f8f32ad3b53c980059ead42808c
#https://github.com/NixOS/nixpkgs/commit/1f6f0c9b3a832f8f32ad3b53c980059ead42808c
let ghcfix = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/1f6f0c9b3a832f8f32ad3b53c980059ead42808c.tar.gz") {};
in { pkgs, config, ... }:
{
  home.packages = with pkgs.haskell.lib; with ghcfix.pkgs.haskell.packages.ghc883; [
    (justStaticExecutables (dontCheck (doJailbreak hledger)))
    (justStaticExecutables (dontCheck (doJailbreak cachix)))
  ];
}

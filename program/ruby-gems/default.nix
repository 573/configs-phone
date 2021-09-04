# in home.nix packages: (import ./program/ruby-gems).wrappedRuby
let
  pkgs = import <nixpkgs> { };
in
pkgs.bundlerEnv {
  name = "gmail-britta-bundler-env";
  gemdir = ./.;
  #gemfile = ./Gemfile;
  #lockfile = ./Gemfile.lock;
  #gemset = ./gemset.nix;
  ruby = pkgs.ruby;
}

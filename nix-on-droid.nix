{ pkgs, ... }:

{
  # Simply install just the packages
  environment.packages = with pkgs; [
    # User-facing stuff that you really really want to have
    #vim  # or some other editor, e.g. nano or neovim
    nano

    # Some common stuff that people expect to have
    #diffutils
    #findutils
    #utillinux
    #tzdata
    #hostname
    #man
    #gnugrep
    #gnupg
    #gnused
    gnutar
    #bzip2
    gzip
    #xz
    #zip
    #unzip
    git
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "21.05";

  # After installing home-manager channel like
  #   nix-channel --add https://github.com/rycee/home-manager/archive/release-20.03.tar.gz home-manager
  #   nix-channel --update
  # you can configure home-manager in here like
  #home-manager.config =
  #  { pkgs, ... }:
  #  {
  #    # insert home-manager config
  #  };
  # make settings https://github.com/t184256/nix-on-droid/issues/62#issuecomment-620043789
  # nix run nixpkgs.openssh -c nix-on-droid switch --max-jobs 0
  # https://discourse.nixos.org/t/home-manager-installation-questions/7204/5
  # hm switch -j0
  # nix run nixpkgs.openssh nixpkgs.home-manager -c home-manager -I home-manager=https://github.com/rycee/home-manager/archive/release-20.03.tar.gz switch --max-jobs 0
  home-manager.config = import ./home.nix;
}

# vim: ft=nix


self: super:
{
  inherit ((import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/f0e75e85.tar.gz;
  })) self super) emacsGit-nox emacsUnstable-nox emacsGcc emacsWithPackagesFromUsePackage;
}

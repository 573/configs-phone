/*{
  # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
  nixpkgs-rev ? "441a7da8080352881bb52f85e910d8855e83fc55"
, nixpkgs-ref ? "refs/heads/nixos-unstable"
, pkgsPath ? builtins.fetchGit {
    name = "nixpkgs-${nixpkgs-rev}";
    url = "https://github.com/nixos/nixpkgs/";
    rev = "${nixpkgs-rev}";
    ref = "${nixpkgs-ref}";
  }
, pkgs ? import pkgsPath { }
, extraFeatures ? pkgs.lib.optionals (!pkgs.stdenv.isAarch64) [
    "dbus"
    "inotify"
  ]
, ...
}:*/
{ pkgs, lib, config, options, ... }:
let
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    #rev = "ac05859dcb3aaa419e858c843ac9dc2602f02ac6"; # 2.4.1
    ref = "refs/tags/3.0.2";
  }) {};
  nix-bisect = mach-nix.buildPythonPackage {
    src = "https://github.com/timokau/nix-bisect/tarball/fed39ee72673e7bf19f6e1ef9ea53b9ccdd7d50c";
    #extras = "appdirs,numpy,pexpect";
    disable_checks = true;
    doCheck = false;
    doInstallCheck = false;
    dontUseSetuptoolsCheck = true;
    pythonImportsCheck = [ ];
  };
  jrnl = mach-nix.buildPythonApplication rec {
    # see https://github.com/DavHau/mach-nix/issues/128
    #  src = "https://github.com/jrnl-org/jrnl/tarball/release";
    version = "2.4.5";
    pname = "jrnl";
    src = mach-nix.nixpkgs.python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "a5f069efcaa3f5d95cc7712178b3f92915f67eed4034e5f257cc063c6b0e74d9";
    };
    disable_checks = true;
    doCheck = false;
    doInstallCheck = false;
    dontUseSetuptoolsCheck = true;
    pythonImportsCheck = [ ];
    # &q=pyproject.toml+requirements+comparison+operator+caret, i. e. ^2.7 in pyproject.toml translates to <3.0,>=2.7 in setuptools
    requirements = ''
      pyxdg<0.27,>=0.26.0
      cryptography<3.0,>=2.7
      passlib<1.8,>=1.7
      parsedatetime<2.5,>=2.4
      keyring>19.0,<22.0
      pytz>=2019.1,<2021.0
      tzlocal>1.5,<3.0
      asteval<0.10,>=0.9.14
      colorama<0.5,>=0.4.1
      python-dateutil<2.9,>=2.8
      pyyaml<5.2,>=5.1
      ansiwrap<0.9,>=0.8.4
      packaging<20.5,>=20.4
      # development
      behave<1.3,>=1.2
      mkdocs<1.1,>=1.0
      black<19.11,>=19.10b0
      toml<0.11,>=0.10.0
      pyflakes<2.3,>=2.2.0
      pytest<5.5,>=5.4.3
    '';
  };
  myMachnix = mach-nix.mkPython {
    disable_checks = true;
    #python = pkgs.python38;
    requirements = ''
      # nix-bisect # braucht eigene Derivation ist weder auf nixpkgs noch pypi (that's why)

      jrnl

      dropbox
      # for dropbox updown: https://github.com/jjssoftware/asustor-dropbox/blob/master/bin/updown.py
      lockfile
      setuptools

      # springer_free_books download reqs
      #curlify
      #openpyxl
      #xlrd
      #tqdm
      requests
      # pandas already on requirements

      # for emacs, also https://nixos.wiki/wiki/Vim#Vim_as_a_Python_IDE
      #python-language-server

      # https://github.com/DavHau/mach-nix/issues/24
      #pyls-mypy
      #pyls-isort
      #pyls-black
    '' + pkgs.lib.strings.optionalString (!pkgs.stdenv.isAarch64) ''
      pygobject
      dbus-python
      gst-python

    '';
    providers = {
      # python-jsonrpc-server seems to cause a strange bug when installing from pypi.
      # We change its provider to nixpkgs
      #python-mypy = "nixpkgs";
      #python-isort = "nixpkgs";
      #python-black = "nixpkgs";
      python-jsonrpc-server = "nixpkgs";
    };
    overridesPost = [
      (
        pythonSelf: pythonSuper: {
          pyls-mypy = pythonSuper.pyls-mypy.overrideAttrs (oa: {
            patches = [ ];
          });
        }
      )
    ];
  };
in
{
  home.packages = with pkgs; [
    #jrnl
    #nix-bisect
    myMachnix
  ] ++ pkgs.lib.optionals (!pkgs.stdenv.isAarch64) (with pkgs; [
    gst_all_1.gstreamer
    gtk3
  ]);

  systemd.user.sockets.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus Socket";
    };
    Socket = {
      ListenStream = "%t/bus";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl --user set-environment DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
    };
    Install = {
      WantedBy = [ "sockets.target" ];
      Also = [ "dbus.service" ];
    };
  };

  systemd.user.services.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus";
      Requires = [ "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.dbus}/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation";
      ExecReload = "${pkgs.dbus}/bin/dbus-send --print-reply --session --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig";
    };
    Install = {
      Also = [ "dbus.socket" ];
    };
  };

  # https://serverfault.com/questions/892465/starting-systemd-services-sharing-a-session-d-bus-on-headless-system
  systemd.user.services.test-dbus = {
    Unit = {
      Description = "Example Service to test D-Bus";
      Requires = [ "dbus.socket" ];
    };
    Service = {
      Type = "dbus";
      ExecStart = "/home/dkahlenberg/test-dbus.py";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.file = {
    "test-dbus.py" = {
      text = ''
        #!${pkgs.coreutils}/bin/env python3
        # This file is /home/me/test-dbus.py
        # Remember to make it executable if you want dbus to launch it
        # It works with both Python2 and Python3

        import dbus
        import dbus.service
        from gi.repository import GLib
        from dbus.mainloop.glib import DBusGMainLoop

        class MyDBUSService(dbus.service.Object):
            def __init__(self):
                bus_name = dbus.service.BusName('org.me.test', bus=dbus.SessionBus())
                dbus.service.Object.__init__(self, bus_name, '/org/me/test')

            @dbus.service.method('org.me.test')
            def hello(self):
                mainloop.quit() # terminate after running. daemons don't use this
                return "Hello,World!"

            @dbus.service.method('org.me.test')
            def Exit(self):
                mainloop.quit()

        DBusGMainLoop(set_as_default=True)
        myservice = MyDBUSService()
        mainloop = GLib.MainLoop()
        mainloop.run()
      '';
      executable = true;
    };

    "bin/orgzlysync.py" = {
      source = pkgs.runCommand "orgzlysync.py"
        {
          input = pkgs.fetchFromGitHub {
            owner = "jjssoftware";
            repo = "asustor-dropbox";
            rev = "9a4bb4d6661cad254f79d5f75d908f04f341abc8";
            sha256 = "0qcm7jc0myyvpmz57bdnssbld856g9a8lnhpblrnx223hpvkfxc8";
          } + "/bin/updown.py";
        } ''
        sed -e "s!import locale!#import locale!g" \
        -e "s!locale.setlocale!#locale.setlocale!g" \
        -e "s!log_filename = ensure_and_get_folder('log')!log_filename = ensure_and_get_folder('log', False)!g" \
        -e "s!processLockFile = ensure_and_get_folder('lock')!processLockFile = ensure_and_get_folder('lock', False)!g" \
        -e "s!ascii_msg += '? \[Y/n\] '!ascii_msg += '? \[Y/n\] '\.encode('ascii', 'ignore')!g" \
          -e "s!ascii_msg += '? \[N/y\] '!ascii_msg += '? \[N/y\] '\.encode('ascii', 'ignore')!g" \
          -e "s:#!/usr/local/bin/:#!${pkgs.coreutils}/bin/env :g" \
        "$input" > "$out"
      '';
      executable = true;
    };

    "jupytertest.ipynb" = {
      # generated from test.md using command:
      # pandoc --from markdown --to ipynb -s --atx-headers --wrap=preserve --preserve-tabs test.md -o test.ipynb
      # I. e. https://github.com/mwouts/jupytext/tree/32303a6c997ce651d96c675f860282d73d5ccd6a/demo
      text = ''
        {
         "cells": [
          {
           "cell_type": "code",
           "execution_count": null,
           "metadata": {},
           "outputs": [],
           "source": [
            "from urllib.request import urlretrieve\n",
            "iris = 'http://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data'\n",
            "urlretrieve(iris)\n",
           ]
          }
         ],
         "nbformat": 4,
         "nbformat_minor": 5,
         "metadata": {
          "jupytext": {
           "formats": "ipynb,.pct.py:percent,.lgt.py:light,.spx.py:sphinx,md,Rmd,.pandoc.md:pandoc",
           "cell_markers": "region,endregion",
           "text_representation": {
            "format_version": 1.1,
            "jupytext_version": "1.1.0",
            "extension": ".md",
            "format_name": "markdown"
           }
          },
          "kernelspec": {
           "name": "python3",
           "display_name": "Python 3",
           "language": "python"
          }
         }
        }
      '';
    };
  };
}

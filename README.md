# configs-phone
config for smartphone

On the very first run I had to tick `xz`, `gzip`, `gnutar` and `git` in the nix-on-droid.nix file and run just `nix-on-droid switch`.

When this succeeded I could do stuff like:

```console
NIX_PATH=nixpkgs=http://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz:home-manager=https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz:nix-on-droid=https://github.com/t184256/nix-on-droid/archive/release-21.05.tar.gz nix-on-droid switch
```

To access my nix session I would (assuming key on remote machine):

```console
$(which sshd) -d -D -f ~/sshd_config_local
```

using the `sshd_config_local` file out my config on the phone.

I'm also using some folders i. e. my orgmode notebooks from orgzly app like this:

```console
sh-4.4$ ls -la ~/orgzly
lrwxrwxrwx 1 nix-on-droid nix-on-droid 26 Nov 14  2020 /data/data/com.termux.nix/files/home/orgzly -> /mnt/sdcard/Notebooks
```


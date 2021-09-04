{ pkgs ? import <nixpkgs> { }, config, lib, ... }:
with lib;
let
  home-manager = with pkgs; writeShellScriptBin "home-manager" ''
    # `toString` is required to impurely track your configuration instead of copying it to `/nix/store`
    exec ${(callPackage ./home-sources.nix { }).home-manager}/bin/home-manager -f ${toString ./home.nix} $@
  '';
in
{
  imports =
    [
      ./program/emacs
    ];

    manual.manpages.enable = false;

  home.packages = with pkgs; 
  [
    home-manager
    gnused
    xz
    curl
    which
    openssh
  ];

  fonts.fontconfig.enable = true;

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "builder" = {
        hostname = "192.168.1.30";
        user = "dani";
        identitiesOnly = true;
        identityFile = "~/.ssh/nix_remote";
      };
    };
  };

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    secureSocket = false;
    extraConfig = ''
      # List of plugins
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'

      # Other examples:
      # set -g @plugin 'github_username/plugin_name'
      # set -g @plugin 'git@github.com/user/plugin'
      # set -g @plugin 'git@bitbucket.com/user/plugin'

      # https://github.com/direnv/direnv/wiki/Tmux
      set-option -g update-environment "DIRENV_DIFF DIRENV_DIR DIRENV_WATCHES"
      set-environment -gu DIRENV_DIFF
      set-environment -gu DIRENV_DIR
      set-environment -gu DIRENV_WATCHES
      set-environment -gu DIRENV_LAYOUT

      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run -b '~/.tmux/plugins/tpm/tpm'

    '';
  };

  programs.bash = {
    enable = true;
    historySize = -1;
    historyFileSize = -1;
    historyControl = [ "ignoredups" "ignorespace" ];
    sessionVariables = {
      DISPLAY = ":0.0";
      LC_CTYPE = "de_DE.UTF-8";
      LANG = "de_DE.UTF-8";
    };

    profileExtra = ''
      # using \$\{config.home.profileDirectory\}
      . "${config.home.profileDirectory}/etc/profile.d/nix-on-droid-session-init.sh"
      # on multi-user arch linux, see gh:NixOS/nix/issues/3051
      #. "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
      # not needed on nix-on-droid
      #export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    '';

    bashrcExtra = ''
    eval "$(direnv hook bash)"
    shopt -s histappend
    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
    '';

    shellAliases = {
      # do not delete / or prompt if deleting more than 3 files at a time #
      rm = "rm -I --preserve-root";

      # confirmation #
      mv = "mv -i";
      cp = "cp -i";
      ln = "ln -i";

      # Parenting changing perms on / #
      chown = "chown --preserve-root";
      chmod = "chmod --preserve-root";
      chgrp = "chgrp --preserve-root";

      cheat = "function _f() { curl cht.sh/\"$1\"; } ; _f";
      # https://stackoverflow.com/questions/3430330/best-way-to-make-a-shell-script-daemon
      # try this as well:
      # https://unix.stackexchange.com/questions/426862/proper-way-to-run-shell-script-as-a-daemon
      # or:
      # https://wiki.jenkins.io/display/JENKINS/Installing+Jenkins+as+a+Unix+daemon
      nrn_oneoff = "function _f() { \\
        ( neuron ~/meinzettelkasten rib serve </dev/null &>~/rib_serve.out & ) & \\
        } ; _f";
    };
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      set mouse=a
      set background=dark
      set statusline+=%#warningmsg#
      set statusline+=%{SyntasticStatuslineFlag()}
      set statusline+=%*
      if has("multi_byte")
        " IDK where I got that from but setting termencoding in any case seems crucial
        "if &termencoding == ""
        "  let &termencoding = &encoding
        "endif
        set encoding=utf-8
        setglobal fileencoding=utf-8
        " Uncomment to have 'bomb' on by default for new files.
        " Note, this will not apply to the first, empty buffer created at Vim startup.
        "setglobal bomb
        set fileencodings=ucs-bom,utf-8,latin1
       endif
      " https://www.reddit.com/r/PowerShell/comments/9ya1un/issues_with_git_nano_and_vim/ea0v0yw/
      set termencoding=utf-8

      augroup HiglightTODO
          autocmd!
          autocmd WinEnter,VimEnter * :silent! call matchadd('Todo', 'TODO\|FIXME\|IMPORTANT', -1)
      augroup END

      " https://github.com/autozimu/LanguageClient-neovim#quick-start
            " https://discourse.nixos.org/t/nix-lsp-language-server-for-nix/894
            " Required for operations modifying multiple buffers like rename.
            set hidden
            let g:LanguageClient_serverCommands = {
                \ 'python': ['pyls']
                \ , 'haskell': ['hie-wrapper', '--lsp']
                \ , 'rust': ['rustup', 'run', 'stable', 'rls']
                \ , 'nix': ['rnix-lsp']
                \ , 'text': ['unified-language-server', '--parser=retext-english', '--stdio']
                \ , 'markdown': ['unified-language-server', '--parser=remark-parse', '--stdio']
                \ , 'sh': ['bash-language-server', 'start']
          \ }

            let g:LanguageClient_loadSettings = 1
      " https://github.com/haskell/haskell-ide-engine#languageclient-neovim
      nnoremap <F5> :call LanguageClient_contextMenu()<CR>
      map <Leader>lk :call LanguageClient#textDocument_hover()<CR>
      map <Leader>lg :call LanguageClient#textDocument_definition()<CR>
      map <Leader>lr :call LanguageClient#textDocument_rename()<CR>
      map <Leader>lf :call LanguageClient#textDocument_formatting()<CR>
      map <Leader>lb :call LanguageClient#textDocument_references()<CR>
      map <Leader>la :call LanguageClient#textDocument_codeAction()<CR>
      map <Leader>ls :call LanguageClient#textDocument_documentSymbol()<CR>

      let diagnosticsDisplaySettings = {
        \       '1': {
        \           'name': 'Error',
        \           'texthl': 'ALEError',
       \           'signText': '¬',
        \           'signTexthl': 'ALEErrorSign',
        \       },
        \       '2': {
        \           'name': 'Warning',
        \           'texthl': 'ALEWarning',
        \           'signText': '!',
        \           'signTexthl': 'ALEWarningSign',
        \       },
        \       '3': {
        \           'name': 'Information',
        \           'texthl': 'ALEInfo',
       \           'signText': 'i',
        \           'signTexthl': 'ALEInfoSign',
        \       },
        \       '4': {
        \           'name': 'Hint',
        \           'texthl': 'ALEInfo',
        \           'signText': 'h',
        \           'signTexthl': 'ALEInfoSign',
       \       },
        \  }

      let g:LanguageClient_diagnosticsDisplay=diagnosticsDisplaySettings
    '';
    plugins = with pkgs.vimPlugins; [
      vim-colors-solarized
      vim-bufferline
      vim-easymotion
      vim-addon-nix
      sensible
      vim-airline
      vim-better-whitespace
    ];
    settings = { ignorecase = true; };
  };

  xdg = {
    enable = true;

    # https://github.com/cachix/cachix/issues/239#issuecomment-654868603 does not work in nix-on-droid
    # https://github.com/jwiegley/nix-config/blob/3106daf3d55c998de711c02f135a38092858c611/config/home.nix

    # https://github.com/t184256/nix-on-droid/issues/83

    configFile = {
"ssh/sshd_config".text = ''
# ${config.xdg.configHome}/ssh/sshd_config
# usage: $(which sshd) -d -D -f ~/.config/ssh/sshd_config # (nmap -p 8023 192.168.1.0/24)
AuthorizedKeysFile   .ssh/authorized_keys
PasswordAuthentication no
Port 8023
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
UsePAM no
PrintMotd no
PermitUserEnvironment no
Banner /etc/issue
# You may generate the host key using: ${pkgs.openssh}/bin/ssh-keygen -q -N "" -t rsa -b 4096 -f ${config.home.homeDirectory}/.ssh/local_sshd/ssh_host_rsa_key
HostKey ~/.ssh/local_sshd/ssh_host_rsa_key
      '';

      "jrnl/jrnl.yaml".text = ''
        colors:
          body: none
          date: none
          tags: none
          title: none
        default_hour: 9
        default_minute: 0
        editor: 'vim'
        encrypt: false
        highlight: true
        indent_character: '|'
        journals:
          default: ${toString config.home.homeDirectory}/.local/share/jrnl/journal.txt
        linewrap: 79
        tagsymbols: '@'
        template: false
        timeformat: '%Y-%m-%d %H:%M'
        version: v2.3
      '';
    };
  };

  home.file = {
    # https://serverfault.com/a/593487
    ".ssh/environment".text = ''
      BASH_ENV=~/.profile
    '';

    "stepdebugsample.sh" = {
      text = ''
        #!${pkgs.coreutils}/bin/env bash
        # https://mobile.twitter.com/b0rk/status/1312413117436104705

        trap '(read -p "[$BASH SOURCE: $LINENO] $BASH COMMAND?")' DEBUG

        var=2

        echo $((var+2))
      '';
      executable = true;
    };

    # https://github.com/jonascarpay/nix/blob/3840e6c20ff46e173600057eb490f8005f0787a7/home-modules/caches.nix#L92
    nixConf = {
      text = ''
        builders-use-substitutes = true
        builders = ssh-ng://builder ;
        max-jobs = 0
        extra-platforms = aarch64-linux
        allowed-users = [ dani ]
        trusted-users = dani
        build-users-group = nixbld
      '';
    };
  };
}

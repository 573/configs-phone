{ pkgs, config, ... }:
let
  myEmacsConfig = pkgs.writeText "default.el" ''
;; -*- lexical-binding: t; -*-

;; https://sanemacs.com/ - A minimal Emacs config that does just enough and nothing more.
(load "./sanemacs.el" nil t)

;; https://github.com/raxod502/straight.el - 🍀 Next-generation, purely functional package manager for the Emacs hacker.
;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Load the straight.el version of use-package
(defvar straight-use-package-by-default)
(straight-use-package 'use-package)
;; Tell straight to use use-package by default
(setq straight-use-package-by-default t)

      ;; Disable startup message.
      (setq inhibit-startup-screen t
	    ;; https://github.com/emacs-dashboard/emacs-dashboard#emacs-daemon
	    initial-buffer-choice (lambda () (get-buffer "*Deft*"))
            ;; initial-buffer-choice 'ignore
            inhibit-startup-echo-area-message (user-login-name))

      (setq initial-major-mode 'fundamental-mode
            initial-scratch-message nil
            inhibit-startup-message t)

      ;; Disable some GUI distractions.
      (tool-bar-mode -1)
      ;; (scroll-bar-mode -1)
      (menu-bar-mode -1)
      (blink-cursor-mode 0)

      ;; Set up fonts early.
      (set-face-attribute 'default
                          nil
                          :height 80
                          :family "Fantasque Sans Mono")
      (set-face-attribute 'variable-pitch
                          nil
                          :family "DejaVu Sans")

;; https://github.com/integral-dw/org-bullets - The MELPA branch from the popular legacy package
(use-package org-bullets
  :init
  (setq org-bullets-bullet-list '("●" "○" "●" "○" "●" "◉" "○" "◆"))
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

;; https://github.com/company-mode/company-mode - Modular in-buffer completion framework for Emacs
(use-package company
  :diminish
  :config
  (global-company-mode 0)
  (setq ;; Only 2 letters required for completion to activate.
        company-minimum-prefix-length 2

        ;; Search other buffers for completion candidates
        company-dabbrev-other-buffers t
        company-dabbrev-code-other-buffers t

        ;; Allow (lengthy) numbers to be eligible for completion.
        company-complete-number t

        ;; M-⟪num⟫ to select an option according to its number.
        company-show-numbers t

        ;; Edge of the completion list cycles around.
        company-selection-wrap-around t

        ;; Do not downcase completions by default.
        company-dabbrev-downcase nil

        ;; Even if I write something with the ‘wrong’ case,
        ;; provide the ‘correct’ casing.
        company-dabbrev-ignore-case t

        ;; Immediately activate completion.
        company-idle-delay 0))

(add-hook 'prog-mode-hook 'company-mode)

(use-package company-emoji
  :config (add-to-list 'company-backends 'company-emoji))

(use-package org
  :bind (
    ("C-c l" . org-store-link)
  )
  :config
  ;; Add some todo keywords.
(setq org-todo-keywords
      '((sequence "TODO(t)"
                  "STRT(s!)"
                  "NEXT(w@/!)"
                  "DLGD(@!)"
                  "|"
                  "DONE(d!)"
                  "DONT(c@!)")))

;; Unfortunately org-mode tends to take over keybindings that
;; start with C-c.
(unbind-key "C-c SPC" org-mode-map)
(unbind-key "C-c w" org-mode-map))

(use-package moe-theme
    :config
    ;; Show highlighted buffer-id as decoration. (Default: nil)
(setq moe-theme-highlight-buffer-id t)

;; Resize titles (optional).
(setq moe-theme-resize-markdown-title '(1.5 1.4 1.3 1.2 1.0 1.0))
(setq moe-theme-resize-org-title '(1.5 1.4 1.3 1.2 1.1 1.0 1.0 1.0 1.0))
(setq moe-theme-resize-rst-title '(1.5 1.4 1.3 1.2 1.1 1.0))

;; Highlight Buffer-id on Mode-line
;; (setq moe-theme-highlight-buffer-id nil)

;; Choose a color for mode-line.(Default: blue)
(setq moe-theme-set-color 'cyan)

;; Finally, apply moe-theme now.
    ;; Choose what you like, (moe-light) or (moe-dark)
    ;; https://www.reddit.com/r/emacs/comments/3tpoae/usepackage_doesnt_load_theme/cx88myw
    :init
(load-theme 'moe-dark t))

(use-package deft
  :after (org-super-links)
  :bind ("C-<f12>" . deft)
  :init
    ;; https://github.com/EFLS/zd-tutorial/blob/80eb8b378db2e44dd9daeb7eb9d49d176fe7ea14/2020-04-17-1532%20Zetteldeft%20and%20Markdown.org
    ;; https://github.com/jrblevin/deft/issues/49#issuecomment-368605084
    (setq deft-extensions '("org")
          deft-text-mode 'org-mode
          deft-directory "~/meinzettelkasten"
          deft-recursive t
          ;; deft-new-file-format "%Y-%m-%dT%H%M"
          deft-use-filename-as-title t
          ;; I tend to write org-mode titles with #+title: (i.e., uncapitalized). Also other org-mode code at the beginning is written in lower case.
          ;; In order to filter these from the deft summary, let’s alter the regular expression:
          deft-strip-summary-regexp
           (concat "\\("
                   "[\n\t]" ;; blank
                   "\\|^#\\+[a-zA-Z_]+:.*$" ;;org-mode metadata
                   "\\)")
          ;; Its original value was \\([\n ]\\|^#\\+[[:upper:]_]+:.*$\\).
          )
)
(setq deft-default-extension "org")

(use-package zetteldeft
  :after (deft)
  :config
    (zetteldeft-set-classic-keybindings)
  :ensure t)

;; https://github.com/EFLS/zd-tutorial
(setq deft-directory "~/orgzly")

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . nil)
   (shell . t)))

(deft)
  '';
#myEarlyInit = ./early-init.el;
sane = builtins.fetchurl "https://sanemacs.com/sanemacs.el";
in { home.packages = with pkgs; [
  git
  findutils # aarch64
    (pkgs.emacsWithPackagesFromUsePackage {
        config = builtins.readFile myEmacsConfig;
        package = pkgs.emacs;
        extraEmacsPackages = epkgs: (with epkgs.melpaPackages; [
          # see https://nixos.org/manual/nixpkgs/stable/#sec-emacs
          (pkgs.runCommand "default.el" {} ''
            mkdir -p $out/share/emacs/site-lisp
            cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
            cp ${sane} $out/share/emacs/site-lisp/sanemacs.el
            echo $out/share/emacs/site-lisp
          '')
        ]) ++ (with epkgs.elpaPackages; [
        ]);
      })
  ];

    # http://ergoemacs.org/emacs/emacs27_features.html - 'Whichever directory Emacs decides to use, it will set user-emacs-directory to point to it. (...) The file is called early-init.el, in user-emacs-directory.'
    home.file = {
      ".emacs.d/early-init.el".text = ''
(setq package-enable-at-startup nil)
(provide 'early-init)
          '';
    };
  }

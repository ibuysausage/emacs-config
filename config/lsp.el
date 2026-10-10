;;; Lsp --- lsp config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;Ace-window setup for easier window switch
(global-set-key (kbd "M-o") 'ace-window)

;;Silence warnings
(defvar lsp-format-buffer-on-save)
(defvar lsp-keymap-prefix)
(defvar lsp-ui-doc-show-with-cursor)
(defvar lsp-ui-sideline-show-diagnostics)

(defvar lsp-nix-nixd-formatting-command)
(defvar lsp-nix-nixd-home-manager-options-expr)
(defvar lsp-nix-nixd-nixos-options-expr)
(defvar lsp-nix-nixd-nixpkgs-expr)
(defvar lsp-nix-nixd-server-path)

(defvar company-backends)
(defvar company-idle-delay)
(defvar company-minimum-prefix-length)

;;Lsp-mode settings
(setq lsp-format-buffer-on-save  t
			lsp-keymap-prefix "C-c l"
			lsp-ui-doc-show-with-mouse nil
			lsp-ui-doc-show-with-cursor t
			lsp-ui-doc-position 'top
			lsp-ui-sideline-show-diagnostics nil)

;;Company settings
(setq company-minimum-prefix-length 1
      company-idle-delay 0.0) ;; default is 0.2

(with-eval-after-load 'company
  (add-to-list 'company-backends '(company-files)))

;;Lsp hooks
(require 'lsp-mode)
(add-hook 'c++-mode-hook #'lsp)
(add-hook 'c-mode-hook #'lsp)
(add-hook 'haskell-literate-mode-hook #'lsp)
(add-hook 'haskell-mode-hook #'lsp)
(add-hook 'nix-mode-hook #'lsp)
(add-hook 'rust-mode-hook #'lsp)

;;Nixd configuaration
(setq lsp-nix-nixd-server-path "nixd"
      lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
      lsp-nix-nixd-formatting-command ["alejandra"]
      lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.wildfire.options"
      lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.wildfire.options.home-manager.users.type.getSubOptions []")

;;Flycheck

;; Check syntax everywhere
(add-hook 'after-init-hook #'global-flycheck-mode)

;; Show diagnostics inline, next to the code (in the spirit of Error Lens)
(add-hook 'after-init-hook #'global-flycheck-annotate-mode)


;;; lsp.el ends here

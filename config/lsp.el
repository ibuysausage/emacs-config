;;; Lsp --- lsp config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package nix-mode
	:mode "\\.nix\\'")
(use-package rust-mode)
(use-package lsp-mode
  :init
	(setq lsp-format-buffer-on-save  t
				lsp-keymap-prefix "C-c l"
				lsp-ui-doc-show-with-mouse nil
				lsp-ui-doc-show-with-cursor t
				lsp-ui-doc-position 'top
				lsp-ui-sideline-show-diagnostics nil)
  :hook (
         (lsp-mode . lsp-enable-which-key-integration)
				 (c++-mode . lsp)
				 (c-mode . lsp)
				 (nix-mode . lsp))
  :commands lsp
	:config
	(setq lsp-nix-nixd-server-path "nixd"
				lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
				lsp-nix-nixd-formatting-command ["alejandra"]
				lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.wildfire.options"
				lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.wildfire.options.home-manager.users.type.getSubOptions []"))

(use-package flycheck
	:hook
	(after-init . global-flycheck-mode)
  (after-init . global-flycheck-annotate-mode))
	
(use-package company
	:commands company-mode
	:init
	(setq company-minimum-prefix-length 1
				company-idle-delay 0.0)
	:config
	(add-to-list 'company-backends '(company-files)))

(use-package lsp-ui :commands lsp-ui-mode)
(use-package which-key
    :config
    (which-key-mode))

;;Indent-blankline for emacs
(use-package indent-bars
	:hook (
				 (rust-mode)
				 (nix-mode)
				 (c-mode)
				 (c++-mode)))
				 
;;Auto pair + indent
(add-hook 'prog-mode-hook #'electric-pair-mode)
(add-hook 'prog-mode-hook #'indent-bars-mode)

;;; lsp.el ends here

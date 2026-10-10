;;; EmacsConfig --- ibuysausage emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;;Do M-x package-install-selected-packages on first run

;;; Code:
;;Import files
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp"))
(require 'eshell-zsh-like)

;;User generated options go in diff file
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;Basic settings
(menu-bar-mode -1) ;Disable top bar
(tool-bar-mode -1) ;Disable tool bar
(scroll-bar-mode -1) ;Disable scroll bar
(global-display-line-numbers-mode 1); Add line numbers
(setq-default tab-width 2); Tab space to 2
(setq make-backup-files nil); No backup files

;;Key Macros
(defvar my/popup-extra-modes '(compilation-mode completion-list-mode Info-mode)
  "Modes treated as popups in addition to anything derived from `special-mode'.")

(defvar my/popup-step 4
  "Columns (or lines, for stacked windows) to resize per keypress.")

(defun my/popup-buffer-p (buf)
  "Non-nil if BUF looks like a popup (the kind you close with q)."
  (with-current-buffer buf
    (or (derived-mode-p 'special-mode)
        (apply #'derived-mode-p my/popup-extra-modes))))

(defun my/popup-window ()
  "Selected window if it's a popup, else the first popup window on this frame."
  (if (my/popup-buffer-p (window-buffer))
      (selected-window)
    (seq-find (lambda (w) (my/popup-buffer-p (window-buffer w)))
              (window-list nil 'never))))

(defun my/popup-resize (delta)
  "Resize the popup window by DELTA (positive grows, negative shrinks)."
  (let ((win (my/popup-window)))
    (cond
     ((null win) (user-error "No popup window on this frame"))
     ((window-combined-p win t)         ; side by side
      (window-resize win (window-resizable win delta t) t))
     ((window-combined-p win)           ; stacked above/below
      (window-resize win (window-resizable win delta nil) nil))
     (t (user-error "Popup is the only window")))))

(defun my/popup-shrink (&optional n)
	 "N."
  (interactive "p")
  (my/popup-resize (- (* (or n 1) my/popup-step))))

(defun my/popup-enlarge (&optional n)
	"N."
  (interactive "p")
  (my/popup-resize (* (or n 1) my/popup-step)))

(defalias 'linechar (kmacro "\\ n"))

(global-set-key (kbd "M-]") #'my/popup-shrink)
(global-set-key (kbd "M-[") #'my/popup-enlarge)


;;Ace-window setup for easier window switch
(global-set-key (kbd "M-o") 'ace-window)

;;External packages from Melpa
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;;Smooth scrolling
(setq scroll-conservatively 10
      scroll-margin 10)

;;Auto-dim inactive windows
(add-hook 'after-init-hook (lambda ()
    (when (fboundp 'auto-dim-other-buffers-mode)
      (auto-dim-other-buffers-mode t))))

(setq-default cursor-in-non-selected-windows nil)

;;NO UGLY COLORS
(require 'auto-dim-other-buffers)

(set-face-attribute 'auto-dim-other-buffers nil
                    :background "#11111b")
(set-face-attribute 'auto-dim-other-buffers-hide nil
                    :foreground "#11111b"
                    :background "#11111b")

(add-to-list 'auto-dim-other-buffers-affected-faces
             '(line-number . (auto-dim-other-buffers . nil)))
(add-to-list 'auto-dim-other-buffers-affected-faces
             '(line-number-current-line . (auto-dim-other-buffers . nil)))

(auto-dim-other-buffers-mode 1)

;;Set font to JetBrains Nerd Font Mono
(let ((mono-spaced-font "Iosevka Nerd Font")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 110)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

;;Set catppuccin-mocha theme
(load-theme 'batppuccin-mocha t)

;;Indent-blankline for emacs
(add-hook 'rust-mode-hook #'indent-bars-mode)
(add-hook 'nix-mode-hook #'indent-bars-mode)
(add-hook 'haskell-mode-hook #'indent-bars-mode)
(add-hook 'haskell-literate-mode-hook #'indent-bars-mode)
(add-hook 'c-mode-hook #'indent-bars-mode)
(add-hook 'c++-hook #'indent-bars-mode)

;;Auto pair mode
(add-hook 'rust-mode-hook #'electric-pair-mode)
(add-hook 'nix-mode-hook #'electric-pair-mode)
(add-hook 'haskell-mode-hook #'electric-pair-mode)
(add-hook 'haskell-literate-mode-hook #'electric-pair-mode)
(add-hook 'c-mode-hook #'electric-pair-mode)
(add-hook 'c++-mode-hook #'electric-pair-mode)



;;Lsp + Autocomplete
;;you know what i mean

;;Silence warnings
(defvar lsp-keymap-prefix)
(defvar lsp-format-buffer-on-save)
(defvar company-minimum-prefix-length)
(defvar company-idle-delay)

(defvar lsp-nix-nixd-server-path)
(defvar lsp-nix-nixd-nixpkgs-expr)
(defvar lsp-nix-nixd-formatting-command)
(defvar lsp-nix-nixd-nixos-options-expr)
(defvar lsp-nix-nixd-home-manager-options-expr)

;;Lsp-mode settings
(setq lsp-keymap-prefix "C-c l")
(setq lsp-format-buffer-on-save  t)
;;Already have diagnostics from flycheck
;;And sideline diagnostics just get in the way
;;Especially with popup windows shown like magit
(setq lsp-ui-sideline-show-diagnostics nil)

;;Company settings
(setq company-minimum-prefix-length 1
      company-idle-delay 0.0) ;; default is 0.2

(with-eval-after-load 'company
  (add-to-list 'company-backends '(company-files)))

(require 'lsp-mode)
(add-hook 'nix-mode-hook #'lsp)
(add-hook 'rust-mode-hook #'lsp)
(add-hook 'haskell-mode-hook #'lsp)
(add-hook 'haskell-literate-mode-hook #'lsp)
(add-hook 'c-mode-hook #'lsp)
(add-hook 'c++-mode-hook #'lsp)

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
;;; init.el ends here

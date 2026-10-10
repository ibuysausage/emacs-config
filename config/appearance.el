;;; Appearance --- appearance config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(menu-bar-mode -1) ;Disable top bar
(tool-bar-mode -1) ;Disable tool bar
(scroll-bar-mode -1) ;Disable scroll bar
(global-display-line-numbers-mode 1); Add line numbers
(setq-default tab-width 2); Tab space to 2
(setq make-backup-files nil); No backup files

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
;;; appearance.el ends here

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

(let ((mono-spaced-font "Iosevka Nerd Font")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 110)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

;;Modeline config
(use-package nerd-icons
	:config
	(setq nerd-icons-scale-factor 1.2))
(use-package doom-modeline
	:config
	(setq doom-modeline-height 35)
  :init (doom-modeline-mode 1))

;;Auto-dim inactive windows
(use-package auto-dim-other-buffers
	:hook (after-init . auto-dim-other-buffers-mode)
	:init
	(setq-default cursor-in-non-selected-windows nil)
	:config
	(auto-dim-other-buffers-mode 1)
  (set-face-attribute 'auto-dim-other-buffers-face nil
                      :background "#11111b")
  (add-to-list 'auto-dim-other-buffers-affected-faces
               '(line-number . (auto-dim-other-buffers-face . nil)))
  (add-to-list 'auto-dim-other-buffers-affected-faces
               '(line-number-current-line . (auto-dim-other-buffers-face . nil))))

(use-package batppuccin
	:config
	(load-theme 'batppuccin-mocha t))

;;; appearance.el ends here

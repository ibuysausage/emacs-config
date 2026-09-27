;; -*- lexical-binding: t; -*-

;;Basic settings
(menu-bar-mode -1) ;Disable top bar
(tool-bar-mode -1) ;Disable tool bar
(scroll-bar-mode -1) ;Disable scroll bar
(global-display-line-numbers-mode 1); Add line numbers

;;External packages
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;;Smooth scrolling
(setq scroll-conservatively 10
      scroll-margin 10)

;;User generated options go in diff file
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;Set font to CaskaydiaCove Nerd Font Mono
(let ((mono-spaced-font "CaskaydiaCove Nerd Font Mono")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 110)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

;;Catppuccin-Mocha theme
(load-theme 'catppuccin :no-confirm)
(setq catppuccin-flavor 'mocha)
(catppuccin-reload)

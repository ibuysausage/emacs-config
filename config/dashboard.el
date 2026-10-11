;;; Dashboard --- Custom emacs dashboard  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; dashboard-open to manually open
(use-package dashboard
	:init
	(setq initial-buffer-choice 'dashboard-open)
	(setq dashboard-banner-logo-title "ibuysausage")
	(setq dashboard-startup-banner "~/.emacs.d/marivector.png")
	(setq dashboard-center-content t)
	(setq dashboard-vertically-center-content t)
  :config
  (dashboard-setup-startup-hook))

;;; dashboard.el ends here

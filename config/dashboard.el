;;; Dashboard --- Custom emacs dashboard  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; dashboard-open to manually open
(use-package dashboard
  :init
  :custom
  (initial-buffer-choice 'dashboard-open) ; Sets dashboard for emacsclient
  (dashboard-startup-banner "~/.emacs.d/marivector.png")
  (dashboard-center-content t)            ; Center content
  (dashboard-vertically-center-content t) ; Center content
  (dashboard-banner-logo-title "ibuysausage")
  (dashboard-items '((recents   . 9)
					 (projects  . 3)))
  :config
  (dashboard-setup-startup-hook))

;;; dashboard.el ends here

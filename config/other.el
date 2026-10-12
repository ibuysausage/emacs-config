;;; Other --- other emacs config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(setq use-short-answers t) ; yes/no -> y/n

;; Auto update pkgs
(use-package auto-package-update
  :config
  (setq auto-package-update-delete-old-versions t)
  (auto-package-update-maybe))

;;; other.el ends here

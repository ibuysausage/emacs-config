;;; Other --- other emacs config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defalias 'yes-or-no-p 'y-or-n-p) ; yes/no -> y/n

;; Auto update pkgs
(use-package auto-package-update
  :config
  (setq auto-package-update-delete-old-versions t)
  (auto-package-update-maybe))

;;; other.el ends here

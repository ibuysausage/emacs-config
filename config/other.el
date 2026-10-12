;;; Other --- other emacs config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(setq use-short-answers t) ; yes/no -> y/n

;; Don't ask when killing a buffer with a live
;; process attched. For vterm
(setq kill-buffer-query-functions
  (remq 'process-kill-buffer-query-function
         kill-buffer-query-functions))

;; Auto update pkgs
(use-package auto-package-update
  :config
  (setq auto-package-update-delete-old-versions t)
  (auto-package-update-maybe))

;;; other.el ends here

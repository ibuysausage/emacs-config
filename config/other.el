;;; Other --- other emacs config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(setq use-short-answers t) ; yes/no -> y/n

(defun kill-all-buffers ()
  "Kill all buffers except default Emacs buffers and *dashboard*."
  (interactive)
  (let ((keep-buffers '("*scratch*" "*Messages*" "*dashboard*")))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (unless (or (member (buffer-name) keep-buffers)
                    (string-prefix-p " " (buffer-name)))
          (kill-buffer buffer))))))

(global-set-key (kbd "C-c k") #'kill-all-buffers)

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

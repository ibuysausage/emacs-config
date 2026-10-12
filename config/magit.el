;;; Magit --- magit config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package magit
  :bind ("C-x g" . magit-status))

(defun my-magit-submodule-update-after-push (process &rest _args)
  "Run the parent submodule updater after a successful submodule push."
  (when (and (memq (process-status process) '(exit))
             (= (process-exit-status process) 0)
             (member "push" (process-command process)))
    (let ((repo (process-get process 'default-dir)))
      (when (and repo
                 (not (equal (file-truename repo)
                             (file-truename "/etc/nixos"))))
        (message "Magit push succeeded; updating parent submodules...")
        (let ((default-directory "/etc/nixos"))
          (make-process
           :name "update-submodules"
           :buffer (get-buffer-create "*submodule-update*")
           :command '("/etc/nixos/update-submodule.sh")
           :sentinel
           (lambda (proc _event)
             (when (memq (process-status proc) '(exit signal))
               (message "Submodule updater finished: %s"
                        (if (and (eq (process-status proc) 'exit)
                                 (= (process-exit-status proc) 0))
                            "success"
                          "failed; inspect *submodule-update*"))))))))))

(with-eval-after-load 'magit
  (advice-add 'magit-process-sentinel
              :after
              #'my-magit-submodule-update-after-push))

;;; magit.el ends here

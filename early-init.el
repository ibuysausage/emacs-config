;;; early-init --- gc optimization -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Temporarily increase GC threshold during startup
(setq gc-cons-threshold most-positive-fixnum)

;; Restore to normal value after startup (e.g. 50MB)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 50 1024 1024))))

;; Emacs startup proceeds through several stages: it loads the early init and
;; regular init files, processes command-line options, sets after-init-time,
;; runs emacs-startup-hook, performs additional initial-frame setup such as
;; applying frame parameters from the configuration, and then runs
;; window-setup-hook after the initial frame parameters have been configured.
;; This makes window-setup-hook a useful place to record a broader startup-time
;; measurement.
;;
;; URL: https://www.jamescherti.com/measuring-emacs-startup-time/
(defvar my-recorded-startup-time-message nil
  "Stores the formatted string of the Emacs startup metrics.")

(defun my-record-startup-time ()
  "Calculate and record the elapsed startup time.
This function records the time when `window-setup-hook' runs."
  (setq my-recorded-startup-time-message
        (format "Emacs loaded in %.2f seconds (Init time: %.2fs) with %d garbage collections."
                (float-time (time-since before-init-time))
                (float-time (time-subtract after-init-time before-init-time))
                gcs-done))
  ;; Output to the *Messages* buffer during the initial launch
  (message "%s" my-recorded-startup-time-message))

(defun my-display-startup-time ()
  "Display the previously recorded Emacs startup time in the echo area."
  (interactive)
  (if my-recorded-startup-time-message
      (message "%s" my-recorded-startup-time-message)
    (message "Startup time was not recorded.")))

;; Read startup summary:
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Startup-Summary.html
(add-hook 'window-setup-hook #'my-record-startup-time 99)

;;; early-init.el ends here

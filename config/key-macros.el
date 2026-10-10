;;; key-macros --- Keyboard macros config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;Ace-window setup for easier window switch
(use-package ace-window
	:config
	(global-set-key (kbd "M-o") 'ace-window))

(defvar my/popup-extra-modes '(compilation-mode completion-list-mode Info-mode)
  "Modes treated as popups in addition to anything derived from `special-mode'.")

(defvar my/popup-step 4
  "Columns (or lines, for stacked windows) to resize per keypress.")

(defun my/popup-buffer-p (buf)
  "Non-nil if BUF looks like a popup (the kind you close with q)."
  (with-current-buffer buf
    (or (derived-mode-p 'special-mode)
        (apply #'derived-mode-p my/popup-extra-modes))))

(defun my/popup-window ()
  "Selected window if it's a popup, else the first popup window on this frame."
  (if (my/popup-buffer-p (window-buffer))
      (selected-window)
    (seq-find (lambda (w) (my/popup-buffer-p (window-buffer w)))
              (window-list nil 'never))))

(defun my/popup-resize (delta)
  "Resize the popup window by DELTA (positive grows, negative shrinks)."
  (let ((win (my/popup-window)))
    (cond
     ((null win) (user-error "No popup window on this frame"))
     ((window-combined-p win t)         ; side by side
      (window-resize win (window-resizable win delta t) t))
     ((window-combined-p win)           ; stacked above/below
      (window-resize win (window-resizable win delta nil) nil))
     (t (user-error "Popup is the only window")))))

(defun my/popup-shrink (&optional n)
	 "N."
  (interactive "p")
  (my/popup-resize (- (* (or n 1) my/popup-step))))

(defun my/popup-enlarge (&optional n)
	"N."
  (interactive "p")
  (my/popup-resize (* (or n 1) my/popup-step)))

(defalias 'linechar (kmacro "\\ n"))

(global-set-key (kbd "M-]") #'my/popup-shrink)
(global-set-key (kbd "M-[") #'my/popup-enlarge)
;;; key-macros.el ends here

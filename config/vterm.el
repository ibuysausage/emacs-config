;;; Vterm --- Emacs vterm config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package vterm
  :commands
  (vterm vterm-other-window)
  :bind
  ("C-<return>" . vterm)
  ("C-M-<return>" . vterm-other-window))
  
;;; vterm.el ends here

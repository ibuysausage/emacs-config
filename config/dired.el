;;; Dired --- dired config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package dired-hide-dotfiles)
(use-package dired
	:ensure nil
	:hook
	(dired-mode . dired-hide-dotfiles-mode))

;;; dired.el ends here

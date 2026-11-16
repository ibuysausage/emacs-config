;;; key-macros --- Keyboard macros config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;Ace-window setup for easier window switch
(use-package ace-window
	:bind ("M-o" . ace-window))

(use-package windsize
	:bind(("M-["  . windsize-left)
				("M-]" . windsize-right))
	:config
	(setq windsize-cols 4)
	(setq windsize-rows 4)
	(windsize-default-keybindings))

;;; key-macros.el ends here

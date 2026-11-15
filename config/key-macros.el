;;; key-macros --- Keyboard macros config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;Ace-window setup for easier window switch
(use-package ace-window
	:bind ("M-o" . ace-window))
(use-package windsize
	:config
	(windsize-default-keybindings))

;;; key-macros.el ends here

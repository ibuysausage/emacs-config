;;; hooks --- mode hooks config  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(add-hook 'dired-mode-hook #'dired-hide-dotfiles-mode)

;;Indent-blankline for emacs
(add-hook 'rust-mode-hook #'indent-bars-mode)
(add-hook 'nix-mode-hook #'indent-bars-mode)
(add-hook 'haskell-mode-hook #'indent-bars-mode)
(add-hook 'haskell-literate-mode-hook #'indent-bars-mode)
(add-hook 'c-mode-hook #'indent-bars-mode)
(add-hook 'c++-hook #'indent-bars-mode)

;;Auto pair mode
(add-hook 'rust-mode-hook #'electric-pair-mode)
(add-hook 'nix-mode-hook #'electric-pair-mode)
(add-hook 'haskell-mode-hook #'electric-pair-mode)
(add-hook 'haskell-literate-mode-hook #'electric-pair-mode)
(add-hook 'c-mode-hook #'electric-pair-mode)
(add-hook 'c++-mode-hook #'electric-pair-mode)

;;; hooks.el ends here

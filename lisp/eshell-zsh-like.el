;;; eshell-zsh-like.el --- Eshell that mirrors zsh + oh-my-posh + fastfetch -*- lexical-binding: t; -*-

;; Needs Emacs 29+. External tools: eza, bat, fastfetch, git (+ lazygit/nvim if you want them).
;; Packages (MELPA / emacsPackages): esh-autosuggest, eshell-syntax-highlighting,
;; pcmpl-args, consult (optional, for the fzf-style C-r history search).

;;; ---------------------------------------------------------------
;;; Packages: autosuggestion, syntax highlighting, completion
;;; ---------------------------------------------------------------
(use-package esh-autosuggest
  :hook (eshell-mode . esh-autosuggest-mode))

(use-package eshell-syntax-highlighting
  :after eshell
  :config (eshell-syntax-highlighting-global-mode +1))

(use-package pcmpl-args
  :after eshell)

;;; ---------------------------------------------------------------
;;; History + completion behaviour
;;; ---------------------------------------------------------------
(setq eshell-history-size 100000
      eshell-hist-ignoredups t
      eshell-save-history-on-exit t
      eshell-cmpl-ignore-case t          ; like NO_CASE_GLOB / matcher-list
      eshell-cmpl-cycle-completions nil
      eshell-scroll-to-bottom-on-input 'this)

;; fzf-style history search on C-r (needs consult)
(with-eval-after-load 'em-hist
  (when (require 'consult nil t)
    (keymap-set eshell-hist-mode-map "C-r" #'consult-history)))

;;; ---------------------------------------------------------------
;;; PATH additions (same as your zsh initContent)
;;; ---------------------------------------------------------------
(dolist (dir (list "/run/current-system/bin"
                   (expand-file-name "~/.cargo/bin")))
  (when (and (file-directory-p dir)
             (not (member dir exec-path)))
    (add-to-list 'exec-path dir t)
    (setenv "PATH" (concat (getenv "PATH") ":" dir))))

;;; ---------------------------------------------------------------
;;; Full-screen programs run in term-mode
;;; ---------------------------------------------------------------
(with-eval-after-load 'em-term
  (dolist (cmd '("nvim" "lazygit" "btop" "htop"))
    (add-to-list 'eshell-visual-commands cmd)))

;;; ---------------------------------------------------------------
;;; Aliases
;;; ---------------------------------------------------------------
(defun my/eshell-setup-aliases ()
  (dolist (a '(("ls"          "eza --icons always --color=always -alh $*")
               ("tree"        "eza -T --icons always --color=always $*")
               ("cat"         "bat --paging=never --color=always $*")
               ("lg"          "lazygit")
               ("v"           "find-file $1")
               ("vnix"        "find-file /etc/nixos")
               ("no"          "yes n")
               ("grabs"       "grim -g ${slurp}")
               ("dockerclean" "docker system prune -a --volumes")
               ("c"           "clear")
               ("ff"          "clear")))
    (apply #'eshell/alias a)))
;; `man' is left alone on purpose: Eshell's built-in `man' opens Emacs's Man-mode,
;; which is better than batman here.
(add-hook 'eshell-mode-hook #'my/eshell-setup-aliases)

;;; ---------------------------------------------------------------
;;; fastfetch on startup and after `clear'
;;; (the kitty image logo can't render in Emacs, so the logo is dropped)
;;; ---------------------------------------------------------------
(defun my/fastfetch ()
  (when (executable-find "fastfetch")
    (ansi-color-apply
     (shell-command-to-string "fastfetch --logo none --pipe false"))))

(setq eshell-banner-message '(concat (my/fastfetch) "\n"))

(defun eshell/clear ()
  "Clear scrollback, then show fastfetch (like the zsh `clear' alias)."
  (eshell/clear-scrollback)
  (my/fastfetch))

;;; ---------------------------------------------------------------
;;; Prompt (oh-my-posh look, built natively)
;;;   [devshell/nsh/venv |] ~/path  branch *  12s
;;;   ❯
;;; ---------------------------------------------------------------
(defvar my/eshell-cmd-start nil
  "Time the last Eshell command started.")

(add-hook 'eshell-pre-command-hook
          (lambda () (setq my/eshell-cmd-start (float-time))))

(defun my/eshell--fg (face)
  "Foreground-only spec from FACE (ansi-color-* faces also set a background)."
  (list :foreground (face-foreground face nil t)))

(defun my/eshell--git-segment ()
  (when (and (not (file-remote-p default-directory))
             (executable-find "git")
             (locate-dominating-file default-directory ".git"))
    (let ((head (with-temp-buffer
                  (when (zerop (call-process "git" nil '(t nil) nil
                                             "rev-parse" "--abbrev-ref" "HEAD"))
                    (string-trim (buffer-string)))))
          (dirty (with-temp-buffer
                   (call-process "git" nil '(t nil) nil "status" "--porcelain")
                   (> (buffer-size) 0))))
      (when (and head (not (string-empty-p head)))
        (concat " "
                (propertize head 'face (my/eshell--fg 'ansi-color-green))
                (when dirty (propertize " *" 'face (my/eshell--fg 'ansi-color-yellow))))))))

(defun my/eshell-prompt ()
  (let* ((ok  (zerop (or eshell-last-command-status 0)))
         (dur (when my/eshell-cmd-start
                (- (float-time) my/eshell-cmd-start)))
         (sep (propertize " | " 'face 'shadow))
         (str
          (concat
           (when (getenv "VIRTUAL_ENV")
             (concat (propertize "🐍 venv" 'face (my/eshell--fg 'ansi-color-yellow)) sep))
           (when (and (getenv "IN_NIX_SHELL") (not (getenv "DEVSHELL_NAME")))
             (concat (propertize "nsh" 'face (my/eshell--fg 'ansi-color-blue)) sep))
           (propertize (abbreviate-file-name (directory-file-name default-directory))
                       'face (my/eshell--fg 'ansi-color-blue))
           (my/eshell--git-segment)
           (when (and dur (> dur 5))
             (concat "  " (propertize (format-seconds "%z%hh %mm %ss" (round dur))
                                      'face (my/eshell--fg 'ansi-color-yellow))))
           "\n"
           (propertize "❯" 'face (my/eshell--fg (if ok 'ansi-color-magenta 'ansi-color-red)))
           " ")))
    (setq my/eshell-cmd-start nil)
    (propertize str
                'read-only t
                'front-sticky '(read-only)
                'rear-nonsticky '(read-only face))))

(setq eshell-prompt-function #'my/eshell-prompt
      eshell-prompt-regexp "^❯ "
      eshell-highlight-prompt nil)

(provide 'eshell-zsh-like)
;;; eshell-zsh-like.el ends here

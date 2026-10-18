;;; nur-bump.el --- Bump GitHub-backed NUR packages -*- lexical-binding: t; -*-

;; Put this file in your Emacs load-path and load it from your init.el, e.g.:
;; (add-to-list 'load-path "~/.emacs.d/site-lisp")
;; (require 'nur-bump)
;; Then use M-x nur-bump or M-x nur-bump-all.  C-u M-x nur-bump-all forces
;; re-prefetching even when the recorded commit is already current.

(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defgroup nur-bump nil
  "Update version and source hashes in a NUR packages repository."
  :group 'tools)

(defcustom nur-bump-max-parallel 4
  "Maximum number of package updates checked/prefetched concurrently."
  :type 'integer
  :group 'nur-bump)

(defcustom nur-bump-report-scale 0.8
  "Approximate width fraction for the batch report window."
  :type 'number
  :group 'nur-bump)

(defface nur-bump-path-face '((t :inherit font-lock-comment-face))
  "Face for the package directory in the report.")
(defface nur-bump-header-face '((t :inherit font-lock-keyword-face :weight bold))
  "Face for report column headers.")
(defface nur-bump-repo-face '((t :inherit font-lock-variable-name-face))
  "Face for GitHub owner/repository names.")
(defface nur-bump-old-face '((t :inherit font-lock-comment-face))
  "Face for old commit hashes.")
(defface nur-bump-new-face '((t :inherit font-lock-constant-face :weight bold))
  "Face for new commit hashes.")
(defface nur-bump-hash-face '((t :inherit font-lock-string-face))
  "Face for fetched source hashes.")
(defface nur-bump-pending-face '((t :inherit shadow))
  "Face for pending jobs.")
(defface nur-bump-running-face '((t :inherit font-lock-builtin-face))
  "Face for running jobs.")
(defface nur-bump-updated-face '((t :inherit success))
  "Face for updated jobs.")
(defface nur-bump-current-face '((t :inherit font-lock-type-face))
  "Face for up-to-date jobs.")
(defface nur-bump-skipped-face '((t :inherit warning))
  "Face for skipped jobs.")
(defface nur-bump-failed-face '((t :inherit error))
  "Face for failed jobs.")

(cl-defstruct (nur-bump--row (:constructor nur-bump--make-row))
  path name repo old new hash state status)

(defconst nur-bump--states
  '((pending . ("·" . nur-bump-pending-face))
    (running . ("…" . nur-bump-running-face))
    (updated . ("✓" . nur-bump-updated-face))
    (current . ("●" . nur-bump-current-face))
    (skipped . ("!" . nur-bump-skipped-face))
    (failed . ("✗" . nur-bump-failed-face))))

(defun nur-bump--notify-error (message)
  (message "NurBump: %s" message)
  (ding))

(defun nur-bump--last-line (string)
  (car (last (split-string (or string "") "\n" t))))

(defun nur-bump--parse-fields (lines)
  "Return (OWNER REPO VERSION) parsed from Nix source LINES."
  (let ((text (string-join lines "\n")) owner repo version)
    (when (string-match "\\_<owner\\_>[ \t]*=[ \t]*\"\\([^\"]+\\)\"" text)
      (setq owner (match-string 1 text)))
    (when (string-match "\\_<repo\\_>[ \t]*=[ \t]*\"\\([^\"]+\\)\"" text)
      (setq repo (match-string 1 text)))
    (when (string-match "\\_<version\\_>[ \t]*=[ \t]*\"\\([^\"]*\\)\"" text)
      (setq version (match-string 1 text)))
    (list owner repo version)))

(defun nur-bump--set-field (lines field value)
  "Replace the first FIELD = \"...\" in LINES with VALUE; return new LINES and success."
  (let ((regexp (concat "\\(" "\\_<" (regexp-quote field) "\\_>"
                        "[ \t]*=[ \t]*\\)\"[^\"]*\"")) found)
    (cons
     (mapcar (lambda (line)
               (if (and (not found) (string-match regexp line))
                   (progn
                     (setq found t)
                     (replace-match (concat (match-string 1 line) "\"" value "\"")
                                    t t line))
                 line))
             lines)
     found)))

(defun nur-bump--apply-bump (lines short-sha hash)
  "Return (UPDATED-LINES VERSION-OK HASH-OK) for LINES."
  (let* ((v (nur-bump--set-field lines "version" short-sha))
         (after-v (car v))
         (h (nur-bump--set-field after-v "sha256" hash))
         (after-h (if (cdr h) (car h)
                    (let ((alternate (nur-bump--set-field after-v "hash" hash)))
                      (setq h alternate)
                      (car alternate)))))
    (list after-h (cdr v) (cdr h))))

(defun nur-bump--run-async (command callback)
  "Run COMMAND asynchronously; call CALLBACK with (STATUS STDOUT STDERR)."
  (let* ((out (generate-new-buffer " *nur-bump-out*"))
         (err (generate-new-buffer " *nur-bump-err*"))
         (proc (make-process
                :name "nur-bump"
                :command command
                :buffer out
                :stderr err
                :noquery t
                :sentinel
                (lambda (process _event)
                  (when (memq (process-status process) '(exit signal))
                    (let ((status (process-exit-status process))
                          (stdout (with-current-buffer out
                                    (buffer-string)))
                          (stderr (with-current-buffer err
                                    (buffer-string))))
                      (when (buffer-live-p out) (kill-buffer out))
                      (when (buffer-live-p err) (kill-buffer err))
                      (funcall callback status stdout stderr)))))))
    proc))

(defun nur-bump--latest-commit (owner repo callback)
  (nur-bump--run-async
   (list "git" "ls-remote" (format "https://github.com/%s/%s" owner repo) "HEAD")
   (lambda (status stdout stderr)
     (if (/= status 0)
         (funcall callback
                  (format "git ls-remote failed: %s"
                          (or (nur-bump--last-line stderr) "unknown error")) nil)
       (if (string-match "\\`\\([[:xdigit:]]+\\)" stdout)
           (funcall callback nil (match-string 1 stdout))
         (funcall callback "couldn't parse commit SHA from git ls-remote output" nil))))))

(defun nur-bump--prefetch-hash (owner repo revision callback)
  (nur-bump--run-async
   (list "nix" "run" "nixpkgs#nix-prefetch-github" "--"
         owner repo "--rev" revision)
   (lambda (status stdout stderr)
     (if (/= status 0)
         (funcall callback
                  (format "nix-prefetch-github failed: %s"
                          (or (nur-bump--last-line stderr) "unknown error")) nil)
       (condition-case err
           (let* ((json-object-type 'alist)
                  (json-key-type 'string)
                  (data (json-read-from-string stdout))
                  (hash (or (alist-get "hash" data nil nil #'equal)
                            (alist-get "sha256" data nil nil #'equal))))
             (if hash
                 (funcall callback nil hash)
               (funcall callback "no hash/sha256 field in prefetch output" nil)))
         (error
          (funcall callback
                   (format "couldn't parse nix-prefetch-github JSON: %s"
                           (error-message-string err)) nil)))))))

(defun nur-bump--buffer-lines ()
  (split-string (buffer-substring-no-properties (point-min) (point-max)) "\n" t))

(defun nur-bump--replace-buffer-lines (lines)
  (let ((point-offset (- (point) (point-min))))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (string-join lines "\n") "\n")
      (goto-char (min (point-max) (+ (point-min) point-offset))))))

;;;###autoload
(defun nur-bump ()
  "Update version and sha256/hash in the current Nix buffer from GitHub HEAD.
The buffer is modified but not saved, so review the diff before writing it."
  (interactive)
  (pcase-let* ((`(,owner ,repo ,_version) (nur-bump--parse-fields (nur-bump--buffer-lines)))
               (buf (current-buffer)))
    (unless (and owner repo)
      (user-error "NurBump: couldn't find owner/repo fields in fetchFromGitHub{}"))
    (message "NurBump: %s/%s — checking newest commit..." owner repo)
    (nur-bump--latest-commit
     owner repo
     (lambda (err full-sha)
       (if err
           (nur-bump--notify-error err)
         (let ((short-sha (substring full-sha 0 (min 7 (length full-sha)))))
           (nur-bump--prefetch-hash
            owner repo full-sha
            (lambda (err2 hash)
              (if err2
                  (nur-bump--notify-error err2)
                (if (not (buffer-live-p buf))
                    (message "NurBump: target buffer was killed; no changes made")
                  (with-current-buffer buf
                    (let* ((old (nur-bump--buffer-lines))
                           (result (nur-bump--apply-bump old short-sha hash))
                           (new (nth 0 result))
                           (ok-v (nth 1 result))
                           (ok-h (nth 2 result)))
                      (nur-bump--replace-buffer-lines new)
                      (if (and ok-v ok-h)
                          (message "NurBump: updated to %s (%s) — buffer not saved" short-sha hash)
                        (display-warning
                         'NurBump
                         (format "Updated partially (version=%s hash=%s); check the buffer"
                                 ok-v ok-h)
                         :warning))))))))))))))

(defun nur-bump--find-pkgs-dir ()
  "Find a `pkgs' directory walking up from the current buffer or `default-directory'."
  (let* ((file (buffer-file-name))
         (dir (file-name-as-directory
               (expand-file-name (if file (file-name-directory file) default-directory))))
         found done)
    (while (and dir (not done))
      (cond
       ((string= (directory-file-name dir) "/")
        (when (file-directory-p "/pkgs") (setq found "/pkgs"))
        (setq done t))
       ((string= (file-name-nondirectory (directory-file-name dir)) "pkgs")
        (setq found (directory-file-name dir) done t))
       ((file-directory-p (expand-file-name "pkgs" dir))
        (setq found (expand-file-name "pkgs" dir) done t))
       (t
        (let ((parent (file-name-directory (directory-file-name dir))))
          (if (or (null parent) (string= parent dir))
              (setq done t)
            (setq dir parent))))))
    (or found
        (let ((fallback (expand-file-name "pkgs" default-directory)))
          (and (file-directory-p fallback) fallback)))))

(defun nur-bump--loaded-buffer (path)
  (let ((expanded (expand-file-name path)) found)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (and buffer-file-name
                   (equal (expand-file-name buffer-file-name) expanded))
          (setq found buf))))
    found))

(defun nur-bump--fit (string width)
  (let* ((width (max 1 width))
         (s (truncate-string-to-width (or string "") width nil nil "…")))
    (concat s (make-string (max 0 (- width (string-width s))) ?\s))))

(defun nur-bump--face-for-state (state)
  (or (cdr (cdr (assq state nur-bump--states))) 'nur-bump-pending-face))

(defun nur-bump--render-report (buffer root rows force)
  "Render the live batch report BUFFER for ROOT and ROWS."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (let* ((win (get-buffer-window buffer t))
             (width (max 48 (if (window-live-p win) (window-body-width win) 100)))
             ;; Keep room for separators; status absorbs extra width.
             (pkg-w (max 8 (min 18 (/ width 7))))
             (repo-w (max 10 (min 25 (/ width 5))))
             (commit-w (max 12 (min 18 (/ width 7))))
             (hash-w (max 16 (min 32 (/ width 4))))
             (status-w (max 8 (- width pkg-w repo-w commit-w hash-w 12)))
             (headers (list (cons "package" pkg-w) (cons "repo" repo-w)
                            (cons "commit" commit-w) (cons "sha256" hash-w)
                            (cons "status" status-w)))
             (counts (make-hash-table :test #'eq))
             (finished 0)
             (total (length rows)))
        (dolist (row rows)
          (let ((state (nur-bump--row-state row)))
            (puthash state (1+ (gethash state counts 0)) counts)
            (when (memq state '(updated current skipped failed))
              (cl-incf finished))))
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (propertize (format " %s%s\n"
                                      (abbreviate-file-name root)
                                      (if force "   forced: re-prefetching everything" ""))
                              'face 'nur-bump-path-face))
          (insert (propertize (make-string (min width 160) ?━) 'face 'shadow) "\n")
          (insert " ")
          (dolist (col headers)
            (insert (propertize (nur-bump--fit (car col) (cdr col)) 'face 'nur-bump-header-face)
                    " │ "))
          (insert "\n" (propertize (make-string (min width 160) ?─) 'face 'shadow) "\n")
          (dolist (row rows)
            (let* ((state (nur-bump--row-state row))
                   (state-data (assq state nur-bump--states))
                   (icon (car (cdr state-data)))
                   (face (nur-bump--face-for-state state))
                   (cells (list
                           (cons (nur-bump--row-name row) 'default)
                           (cons (or (nur-bump--row-repo row) "") 'nur-bump-repo-face)
                           (cons (if (or (nur-bump--row-old row) (nur-bump--row-new row))
                                     (format "%s → %s"
                                             (or (nur-bump--row-old row) "?")
                                             (or (nur-bump--row-new row) "…")) "")
                                 'nur-bump-new-face)
                           (cons (or (nur-bump--row-hash row) "") 'nur-bump-hash-face)
                           (cons (format "%s %s" icon (or (nur-bump--row-status row) "pending")) face)))
                   (first t))
              (insert " ")
              (cl-mapc
               (lambda (cell column)
                 (unless first (insert " │ "))
                 (setq first nil)
                 (insert (propertize (nur-bump--fit (car cell) (cdr column))
                                     'face (cdr cell)))
                 )
               cells headers)
              (insert "\n")))
          (insert (propertize (make-string (min width 160) ?─) 'face 'shadow) "\n")
          (let* ((labels (mapconcat
                          (lambda (state)
                            (format "%s %d %s"
                                    (car (cdr (assq state nur-bump--states)))
                                    (gethash state counts 0)
                                    (symbol-name state)))
                          '(updated current skipped failed) "   "))
                 (bar-width (max 10 (- width (string-width labels) 15)))
                 (filled (if (> total 0) (floor (* bar-width (/ (float finished) total))) 0)))
            (insert " " (propertize (make-string filled ?█) 'face 'nur-bump-updated-face)
                    (propertize (make-string (max 0 (- bar-width filled)) ?░) 'face 'shadow)
                    (format "  %d/%d   %s%s\n" finished total labels
                            (if (= finished total) "   done" "   working…"))))
          (goto-char (point-min)))))))

(defun nur-bump--report-mode ()
  (special-mode)
  (setq-local truncate-lines t)
  (local-set-key (kbd "q") #'quit-window)
  (local-set-key (kbd "<escape>") #'quit-window))

(defun nur-bump--set-row (report root rows force row state status)
  (setf (nur-bump--row-state row) state
        (nur-bump--row-status row) status)
  (nur-bump--render-report report root rows force))

(defun nur-bump--process-row (row report root rows force done)
  (pcase-let ((`(,owner ,repo ,version)
               (with-temp-buffer
                 (insert-file-contents (nur-bump--row-path row))
                 (nur-bump--parse-fields (nur-bump--buffer-lines)))))
    (if (not (and owner repo))
        (progn
          (nur-bump--set-row report root rows force row 'skipped
                             "no fetchFromGitHub owner/repo found")
          (funcall done))
      (setf (nur-bump--row-repo row) (concat owner "/" repo)
            (nur-bump--row-old row) version)
      (nur-bump--set-row report root rows force row 'running "checking newest commit…")
      (nur-bump--latest-commit
       owner repo
       (lambda (err full-sha)
         (if err
             (progn
               (nur-bump--set-row report root rows force row 'failed err)
               (funcall done))
           (let ((short-sha (substring full-sha 0 (min 7 (length full-sha)))))
             (setf (nur-bump--row-new row) short-sha)
             (if (and (equal version short-sha) (not force))
                 (progn
                   (nur-bump--set-row report root rows force row 'current "up to date")
                   (funcall done))
               (nur-bump--set-row report root rows force row 'running "prefetching sha256…")
               (nur-bump--prefetch-hash
                owner repo full-sha
                (lambda (err2 hash)
                  (if err2
                      (progn
                        (nur-bump--set-row report root rows force row 'failed err2)
                        (funcall done))
                    (setf (nur-bump--row-hash row) hash)
                    (let ((buf (nur-bump--loaded-buffer (nur-bump--row-path row))))
                      (if (and buf (buffer-modified-p buf))
                          (progn
                            (nur-bump--set-row report root rows force row 'skipped
                                               "buffer has unsaved changes (hash shown above)")
                            (funcall done))
                        (condition-case write-err
                            (let* ((lines (with-temp-buffer
                                            (insert-file-contents (nur-bump--row-path row))
                                            (nur-bump--buffer-lines)))
                                   (result (nur-bump--apply-bump lines short-sha hash))
                                   (new-lines (nth 0 result)))
                              (unless (and (nth 1 result) (nth 2 result))
                                (error "couldn't find a version and/or sha256/hash field"))
                              (with-temp-buffer
                                (insert (string-join new-lines "\n") "\n")
                                (write-region (point-min) (point-max)
                                              (nur-bump--row-path row) nil 'silent))
                              (when (buffer-live-p buf)
                                (with-current-buffer buf
                                  (revert-buffer :ignore-auto :noconfirm)))
                              (nur-bump--set-row report root rows force row 'updated "updated"))
                          (error
                           (nur-bump--set-row report root rows force row 'failed
                                              (error-message-string write-err))))
                        (funcall done))))))))))))))

;;;###autoload
(defun nur-bump-all (force)
  "Bump all `pkgs/*/default.nix' files under the discovered pkgs directory.
With prefix argument FORCE (C-u), prefetch again even if versions are current."
  (interactive "P")
  (let* ((pkgs-dir (nur-bump--find-pkgs-dir))
         (files (when pkgs-dir
                  (cl-loop for dir in (directory-files pkgs-dir t "^[^.].*" t)
                           when (and (file-directory-p dir)
                                     (file-regular-p (expand-file-name "default.nix" dir)))
                           collect (expand-file-name "default.nix" dir)))))
    (unless pkgs-dir
      (user-error "NurBump: couldn't find a pkgs/ directory above this buffer or cwd"))
    (unless files
      (user-error "NurBump: no pkgs/*/default.nix found under %s" pkgs-dir))
    (let* ((rows (mapcar (lambda (path)
                           (nur-bump--make-row
                            :path path
                            :name (file-name-nondirectory
                                   (directory-file-name (file-name-directory path)))
                            :state 'pending :status "pending"))
                         files))
           (report (get-buffer-create "*NurBumpAll*"))
           (root pkgs-dir))
      (with-current-buffer report (nur-bump--report-mode))
      (let ((window (display-buffer report '((display-buffer-pop-up-window)))))
        (when (window-live-p window)
          (let ((target-width (max 50 (floor (* (frame-width) nur-bump-report-scale)))))
            (when (and (window-splittable-p window t)
                       (< (window-total-width window) target-width))
              (ignore-errors (window-resize window (- target-width (window-total-width window)) t))))))
      (nur-bump--render-report report root rows force)
      (let ((next-index 0) (active 0) (finished 0) (total (length rows)))
        (cl-labels
            ((launch
              ()
              (while (and (< active (max 1 nur-bump-max-parallel)) (< next-index total))
                (let ((row (nth next-index rows)))
                  (cl-incf next-index)
                  (cl-incf active)
                  (nur-bump--process-row
                   row report root rows force
                   (lambda ()
                     (cl-decf active)
                     (cl-incf finished)
                     (if (= finished total)
                         (message "NurBump: finished — %d updated, %d current, %d skipped, %d failed"
                                  (cl-count 'updated rows :key #'nur-bump--row-state)
                                  (cl-count 'current rows :key #'nur-bump--row-state)
                                  (cl-count 'skipped rows :key #'nur-bump--row-state)
                                  (cl-count 'failed rows :key #'nur-bump--row-state))
                       (launch))))))))
          (launch))))))

(provide 'nur-bump)
;;; nur-bump.el ends here

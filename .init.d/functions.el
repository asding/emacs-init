;;;;;;;;;;;;;;;; Movements ;;;;;;;;;;;;;;;;
(defun move-to-scratch ()
  "Switch to buffer named *scratch* and create if it does not exist"
  (interactive)
  (switch-to-buffer
   (get-buffer-create "*scratch*")))
(defun move-to-working-memory ()
  (interactive)
  (find-file "~/.emacs.d/.personal.d/org/notes/working-memory.org"))
(defun jump-to-mark () ;; rebinds C-u C-SPC, will pop local mark ring and move there
  (interactive)
  (set-mark-command 1))
(defun jump-to-global-mark () ;; rebinds C-x C-@, will pop global mark ring and move between buffers
  (interactive)
  (pop-global-mark))
(defun toggle-comment-on-line ()
  (interactive)
  (comment-or-uncomment-region (line-beginning-position) (line-end-position)))
(defun kill-back-to-indentation ()
  "Kill from point back to the first non-whitespace character on the line."
  (interactive)
  (let ((prev-pos (point)))
    (back-to-indentation)
    (kill-region (point) prev-pos)))
(defun reindent-whole-buffer ()
  "Recompute indentation for the whole buffer."
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (indent-region (point-min) (point-max))
    (pop-mark) ;; do not store extra marks
    (pop-mark)))

(defun counsel-projectile-switch-project-action-dwim (project)
  "Jump to a file in PROJECT."
  (let ((projectile-switch-project-action
         (lambda () (magit-status-on-toplevel-if-possible))))
    (counsel-projectile-switch-project-by-name project)))

(defun magit-status-on-toplevel-if-possible ()
  "If the project being switched to is a git repository, invoke
magit-status on the project root directory. Use dired otherwise."
  (interactive)
  (if (and (executable-find "git")
           (eq (projectile-project-vcs) 'git)
           (string-equal (magit-toplevel) (projectile-project-root)))
      (magit-status (projectile-project-root))
    (find-file (projectile-project-root))))

;;;;;;;;;;;;;;;; Editings ;;;;;;;;;;;;;;;;
(defun copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring.
    Ease of use features:
    - Move to start of next line
    - Appends the copy on sequential calls
    - Use newline as last char even on the last line of the buffer
    - If region is active, copy its lines."
  (interactive "p")
  (let ((b (line-beginning-position))
        (e (line-end-position arg)))
    (when mark-active
      (if (> (point) (mark))
          (setq b (save-excursion (goto-char (mark)) (line-beginning-position)))
        (setq e (save-excursion (goto-char (mark)) (line-end-position)))))
    (if (eq last-command 'copy-line)
        (kill-append (buffer-substring b e) (< e b))
      (kill-ring-save b e)))
  (kill-append "\n" nil)
  (beginning-of-line (or (and arg (1+ arg)) 2))
  (if (and arg (not (= 1 arg))) (message "%d lines copied" arg)))

(defun duplicate-line ()
  "Deactivate any active mark, duplicates current line, saves horizontal position, and moves to the next line"
  (interactive)
  (save-excursion
    (deactivate-mark)
    (copy-line nil)
    (yank))
  (next-line))

(defun top-join-line ()
  "Join the current line with the line beneath it."
  (interactive)
  (delete-indentation 1))

(defun open-line-and-indent (arg)
  "Call open line and immediately indent the next line"
  (interactive "p")
  (save-excursion
    (open-line arg)
    (indent-according-to-mode)
    (next-line 1)
    (indent-according-to-mode)))

;;;;;;;;;;;;;;;; Tramp ;;;;;;;;;;;;;;;;
;; TODO: figure out how to call ivy more elegantly, this is basically copy pasting
;; uses ivy methods for convenience
(defun tramp-completion-list (method)
  ;; provide a completion list, based on ivy and tramp-get-completion-function
  ;; METHOD is connection method to remote, can be ssh ftp, will be passed to (tramp-get-completion-function method)
  (let (clist)
    (dolist (x (tramp-get-completion-function method))
      (setq clist (append clist (funcall (car x) (cadr x)))))
    (setq clist (cl-delete-duplicates (delq nil clist) :test #'equal))
    (mapcar #'ivy-build-tramp-name clist)))
;; temporary convenience functions until better solutions can be found, I'm relatively happy with the hackish result
(defun dired-remote-alias (ssh-alias &optional arg)
  "Connect to remote with tramp, projectile alternative until it works"
  (interactive (list (ivy-read "Enter ssh-alias: "
                               (tramp-completion-list "ssh") )
                     (prefix-numeric-value current-prefix-arg)))
  (if (> arg 1)
      (dired (format "/ssh:%s|sudo:%s:" ssh-alias ssh-alias))
    (dired (format "/scp:%s:" ssh-alias))))

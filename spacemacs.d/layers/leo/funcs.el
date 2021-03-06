;;; Functions

(defun leo-add-checkouts ()
  "Add any directories under \"checkouts\" to the front of the
  load path. The intended usage is to symlink the
  source-directory of an emacs-lisp package so that you can hack
  on it, or use a version that is not in melpa yet."
  (let ((checkouts-dir (expand-file-name (concat user-emacs-directory "checkouts"))))
    (when (file-exists-p checkouts-dir)
      (dolist (d (directory-files-and-attributes checkouts-dir))
        (let ((dirname (car d))
              (is-dir  (car (cdr d))))
          (when (and is-dir (not (equal dirname ".")) (not (equal dirname "..")))
            (add-to-list 'load-path (expand-file-name (concat user-emacs-directory "checkouts/" dirname)))))))))

;; (require 'ansi-color)
(defun ansify-buffer ()
  (interactive)
  (ansi-color-apply-on-region (point-min) (point-max)))

(defun leo-spacemacs-user-config ()
  "Called from .spacemacs.d/init.el, after layers are configured."
  (leo-add-checkouts)
  (global-centered-cursor-mode)
  (setq-default
   evil-shift-width 2
   js-indent-level 2
   js2-basic-offset 2
   json-reformat:indent-width 2
   typescript-indent-level 2
   web-mode-code-indent-offset 2
   web-mode-css-indent-offset 2
   web-mode-markup-indent-offset 2
   neo-smart-open t
   ))

(defun leo-neotree-find-buffer-file ()
  (interactive)
  (let ((origin-buffer-file-name (buffer-file-name))
        (project-root (projectile-project-root)))
    (setq neo-force-change-root t)
    (neotree-hide)
    (neotree-find project-root)
    (neotree-find origin-buffer-file-name)))

(defun leo-cider-find-and-clear-repl-buffer ()
  (interactive)
  (cider-find-and-clear-repl-output t))

(defun leo-cider-debug-test-at-point ()
  (interactive)
  (cider-debug-defun-at-point)
  (cider-test-run-test))

(defun leo-magit-display-buffer-function (buffer)
  "Replacement for `magit-display-buffer-traditional', which does
  not work right."
  (display-buffer
   buffer (if (and (derived-mode-p 'magit-mode)
                   (not (memq (with-current-buffer buffer major-mode)
                              '(magit-process-mode
                                magit-revision-mode
                                magit-diff-mode
                                magit-stash-mode
                                magit-status-mode))))
              '(display-buffer-same-window)
            ;; The following is the only difference from
            ;; `magit-display-buffer-traditional' - pass t instead of nil to
            ;; display-buffer
            t)))

(defun leo-with-messages-inhibited (oldfun &rest args)
  (let ((inhibit-message t))
    (apply oldfun args)))

(defun leo-stfu (func)
  (advice-add 'super-save-command :around #'leo-with-messages-inhibited))

(defun leo-cider-open-round ()
  (interactive)
  (end-of-buffer)
  (evil-insert-state)
  (paredit-open-round))

(defun leo-cider-debug-mode-hook (&rest args)
  (message "Debug mode: %s" cider--debug-mode)
  (evil-smartparens-mode (if cider--debug-mode -1 1)))

(defun leo-cider-configure-debugging ()
  ;; Turn off evil-smartparens when debugging, because it overrides some of the
  ;; debugger's keybindings (eg: "c" for continue). This should be OK because
  ;; the cider debugger makes the buffer read-only anyway.
  ;; cider--debug-mode-hook does not seem to fire when exiting debug mode
  ;; (although the docs say it should), so we have to hack it a bit by advising
  ;; cider--debug-remove-overlays to turn evil-smartparens back on when
  ;; debugging is finished.
  (add-hook 'cider--debug-mode-hook #'leo-cider-debug-mode-hook)
  (advice-add 'cider--debug-remove-overlays :after #'leo-cider-debug-mode-hook))

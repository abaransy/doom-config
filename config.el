;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font "Operator Mono Medium 18"
       doom-variable-pitch-font (font-spec :family "Operator Mono" :size 16 :weight 'book))

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))
;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'manoj-dark)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;; Automatically turn on smerge if merge conflicts are detected
(defun sm-try-smerge ()
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^<<<<<<< " nil t)
      (smerge-mode 1))))
(add-hook 'find-file-hook 'sm-try-smerge t)
;; Change smerge prefix
;; (setq smerge-command-prefix "\C-cv")


;; Function and hook to search node_modules for eslint before using global one
;;(defun my/use-eslint-from-node-modules ()
;;  (let* ((root (locate-dominating-file
;;                (or (buffer-file-name) default-directory)
;;                "node_modules"))
;;         (eslint (and root
;;                      (expand-file-name "node_modules/eslint/bin/eslint.js"
;;                                        root))))
;;    (when (and eslint (file-executable-p eslint))
;;      (setq-local flycheck-javascript-eslint-executable eslint))))
;;(add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)


;; Request to disable certain checkers
;;
;; Disable typescript-tide checker with the assumption that we're using eslint
;;(setq-default flycheck-disabled-checkers '(typescript-tide))


;; Functions to format files on save using eslint and prettier
(defun eslint-fix-file ()
  (message "eslint --fixing the file" (buffer-file-name))
  (call-process-shell-command (concat "eslint --fix " (buffer-file-name))))

(defun prettier-fix-file ()
  (message "prettifying the file" (buffer-file-name))
  (call-process-shell-command (concat "prettier --print-width 80 -w " (buffer-file-name))))

(defun eslint-fix-file-and-revert ()
  (eslint-fix-file)
  (revert-buffer t t))

(defun prettier-fix-file-and-revert ()
  (prettier-fix-file)
  (revert-buffer t t))

(defun fix-file ()
  (interactive)
  (when (yes-or-no-p (format "Save and format file %s? " buffer-file-name))
        (save-buffer)
        (prettier-fix-file-and-revert)
        (eslint-fix-file-and-revert)))

(global-set-key (kbd "C-x c") 'fix-file)


;;Functions to format the diff.
(defun fix-diff ()
  (interactive)
  (when (yes-or-no-p (format "Save and format diff?"))
    (call-process-shell-command (format "git diff --name-only --diff-filter=d %s | xargs prettier -w"
                                        (magit-get-upstream-branch)))
   (call-process-shell-command (format "git diff --name-only --diff-filter=d %s | xargs eslint --fix"
                                        (magit-get-upstream-branch)))))

(global-set-key (kbd "C-x j") 'fix-diff)


;; Configure auto saving
(setq auto-save-interval 300)
(setq auto-save-timeout 10)
(defun save-buffer-if-visiting-file (&optional args)
   "Save the current buffer only if it is visiting a file"
   (interactive)
   (if (and (buffer-file-name) (buffer-modified-p))
       (save-buffer args)))

(add-hook 'auto-save-hook 'save-buffer-if-visiting-file)


;; Add Todo states for org mode todos
(after! org
  (setq org-todo-keywords
        '((sequence "TODO" "IN-PROGRESS" "WAITING" "DONE" "KILL"))))

;; Copy/past to system clipboard
(defun copy-to-clipboard ()
  "Copies selection to x-clipboard."
  (interactive)
  (if (display-graphic-p)
      (progn
        (message "Yanked region to x-clipboard.")
        (call-interactively 'clipboard-kill-ring-save)
        )
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning) (region-end) "pbcopy")
          (message "Yanked region to clipboard.")
          (deactivate-mark))
      (message "No region active; can't yank to clipboard!")))
  )

(defun paste-from-clipboard ()
  "Pastes from x-clipboard."
  (interactive)
  (if (display-graphic-p)
      (progn
        (clipboard-yank)
        (message "graphics active")
        )
    (insert (shell-command-to-string "pbpaste"))
    )
  )

(setq auth-sources '("~/.authinfo.gpg"))


;; add a keybinding for opening the code review transient api
(global-set-key (kbd "C-x t") 'code-review-transient-api)
(global-set-key (kbd "C-x n") 'code-review-comment-jump-next)

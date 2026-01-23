;; FUNCTIONS & MACROS
;; straight.el bootstrap function
(defun bootstrap-straight ()
       (progn
	 (defvar bootstrap-version)
	 (let ((bootstrap-file
		(expand-file-name
		 "straight/repos/straight.el/bootstrap.el"
		 (or (bound-and-true-p straight-base-dir)
		     user-emacs-directory)))
	       (bootstrap-version 7))
	   (unless (file-exists-p bootstrap-file)
	     (with-current-buffer
		 (url-retrieve-synchronously
		  "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
		  'silent 'inhibit-cookies)
	       (goto-char (point-max))
	       (eval-print-last-sexp)))
	   (load bootstrap-file nil 'nomessage))
	 (straight-use-package 'use-package)))

(defmacro use-package-ensure! (name &rest plist)
  " Declares and configures a package, while ensuring it's installed.
This is a thin wrapper around `use-package', and exists so I can make sure
that platforms that don't use `straight.el' can still install packages without
control flow being embedded around every `use-package' call and creating a ton
of copy-pasted code that's hard to maintain.

name is the name of the package, and the plist is the property list
(:prelude (), :init (), :config (), :hook (), etc.)

This code assumes you have already set (straight-use-package 'use-package),
which may not be the case. In an ideal world I'd allocate time to fixing this
by checking and enabling it myself if it's not enabled."
  (declare (indent 1))
  (if (eq system-type 'android)
      (if (eq plist t)
	  (progn
	    (setq plist (append plist '(:ensure t)))
	    (list 'use-package name plist))
	(list 'use-package name ':ensure 't))
    (list 'use-package name ':straight 't plist)))

;; Configure modus-vivendi for both mobile and desktop, this code will have to
;; be changed when I install and configure autodark package
(defun init-modus-vivendi ()
  (progn
    (setq modus-vivendi-palette-overrides
      '((bg-main "#242424")
	(bg-dim "#231e1f")
	(fg-main "#dfe6e4")
	(fg-dim "#b9bfbd")
	(fg-alt "#bde9db")))
    (setq modus-themes-mixed-fonts t)
    (setq modus-themes-syntax '(faint))
    (setq modus-themes-variable-pitch-ui t)
    (setq modus-themes-headings
	  '((1 . (variable-pitch 1.5))
	    (2 . (variable-pitch semibold 1.4))
	    (3 . (variable-pitch medium 1.3))
	    (4 . (variable-pitch regular 1.2))
	    (agenda-date . (1.3))
	    (agenda-structure . (variable-pitch light 1.8))
	    (t . (1.1))))
    (load-theme 'modus-vivendi t)))

;; Variables common to mobile and desktop
(defun set-common-vars ()
  (progn
    (setq use-short-answers t
	  visible-bell t
	  history-length 25
	  global-auto-revert-non-file-buffers t
	  custom-safe-themes t
	  inhibit-startup-message t)
    (setq-default fill-column 80)))

;; Modes and functions common to mobile and desktop
(defun setup-common-modes-functions ()
  (progn
    (savehist-mode 1)
    (save-place-mode 1)
    (global-auto-revert-mode 1)
    (global-visual-line-mode 1)
    (global-display-line-numbers-mode 1)
    (dolist (mode '(org-mode-hook term-mode-hook eshell-mode-hook))
      (add-hook mode (lambda () (display-line-numbers-mode -1))))
    (add-hook 'org-mode-hook 'variable-pitch-mode)
    (add-hook 'prog-mode-hook 'eglot-ensure)
    (add-hook 'prog-mode-hook 'global-display-fill-column-indicator-mode)
    (fido-vertical-mode 1)
    (recentf-mode 1)
    (init-modus-vivendi)))

(defun desktop-initial-setup ()
  (progn
    (setq scroll-conservatively 101	    	    
	  use-dialog-box nil)
    (set-common-vars)
    (setup-common-modes-functions)
    (menu-bar-mode -1)
    (tool-bar-mode -1)
    (scroll-bar-mode -1)
    (bootstrap-straight)))

(defun mobile-initial-setup ()
  (setq use-dialog-box t	     
	custom-safe-themes t
	inhibit-startup-message t
	tool-bar-position 'bottom)
  (set-common-vars)
  (setup-common-modes-functions)
  (modifier-bar-mode 1)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (package-initialize)
  (menu-bar-mode 1))

;; some utility functions that are useful outside of config
(defun read-lines-from-file (filePath)
  "Return a list of lines of a file at filePath."
  (interactive "fFile: ")
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string (buffer-string) "\n" t)))
;; The same function but just to read the entire file as a single string
(defun read-string-from-file (filePath)
  "Return the contents of a file as a string"
  (interactive "fFile: ")
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

;; GENERAL CONFIG
(if (eq system-type 'android)
    (mobile-initial-setup)
  (desktop-initial-setup))

;; Alongside other problems caused by android, we have to make sure the home
;; directory for the rest of our config actually points to the files on both
;; desktop and mobile. Android's general home folder is stored at
;;`/storage/emulated/0', when the `~' folder in android emacs is set to
;;`/data/data/org.gnu.emacs/files'. So we create an `agnostic-home-dir'
;; variable to concatenate with a relative path to home.
(if (eq system-type 'android)
    (setq agnostic-home-dir "/storage/emulated/0")
  (setq agnostic-home-dir "~"))

;; CONFIG OF PRE-INSTALLED EMACS PACKAGES
;; I DON'T KNOW WHY THIS `use-package' BLOCK DOESN'T WORK
;; (use-package org
;;   :config (
;; 	   (setq diary-file
;; 		 (concat agnostic-home-dir "/Documents/org/diary.org"))
;; 	   (setq org-directory
;; 		 (concat agnostic-home-dir "/Documents/org/"))
;; 	   (setq org-agenda-files
;; 		 (directory-files-recursively
;; 		  (concat agnostic-home-dir "/Documents/org/") "\\.org$"))
;; 	   (setq org-agenda-start-with-log-mode t)
;; 	   (setq org-log-done 'time)
;; 	   (setq org-log-into-drawer t)
;; 	   (setq org-refile-targets
;; 		 `(("Archive.org" :maxlevel . 1)))
;; 	   (advice-add 'org-refile :after 'org-save-all-org-buffers)))

(when (require 'org nil 'noerror)
  (setq diary-file
	(concat agnostic-home-dir "/Documents/org/diary.org"))
  (setq org-directory (concat agnostic-home-dir "/Documents/org/"))
  (setq org-agenda-files
	(directory-files-recursively
	 (concat agnostic-home-dir "/Documents/org/") "\\.org$"))
  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-refile-targets
	`(("Archive.org" :maxlevel . 1)))
  (advice-add 'org-refile :after 'org-save-all-org-buffers))

		 

;; INSTALL NEW PACKAGES AND CONFIG THEM
(use-package-ensure! rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))
(use-package-ensure! magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))
(use-package-ensure! helpful
  :bind (("C-h f" . helpful-callable)
	 ("C-h v" . helpful-variable)
 	 ("C-h k" . helpful-key)
 	 ("C-h x" . helpful-command)
 	 ("C-h C-d" . helpful-at-point)))
(use-package-ensure! doom-modeline
  :config (doom-modeline-mode 1))

;; BINDINGS
;; Access a fancier buffer list
(global-set-key (kbd "C-x C-b") 'ibuffer)

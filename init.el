;; BOOTSTRAPPING
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
(bootstrap-straight)
(straight-use-package 'org)
(setq evil-want-keybinding nil)

;; functions & macros

(defmacro use-package-ensure! (name &rest plist)
  " declares and configures a package, while ensuring it's installed.
this is a thin wrapper around `use-package', and exists so i can make sure
that platforms that don't use `straight.el' can still install packages without
control flow being embedded around every `use-package' call and creating a ton
of copy-pasted code that's hard to maintain.

name is the name of the package, and the plist is the property list
(:prelude (), :init (), :config (), :hook (), etc.)

this code assumes you have already set (straight-use-package 'use-package),
which may not be the case. in an ideal world i'd allocate time to fixing this
by checking and enabling it myself if it's not enabled."
  (declare (indent 1))
   (let ((package-manager-key (if (eq system-type 'android) :ensure :straight)))
    (if plist
        ;; if there are additional arguments, add the package manager key
        `(use-package ,name ,package-manager-key t ,@plist)
      ;; if no additional arguments, just use the package manager key
      `(use-package ,name ,package-manager-key t))))

(defmacro use-package-desktop! (name &rest plist)
  "declares desktop-exclusive packages, this is to save me the hassle of using
control flow"
  (declare (indent 1))
  (if (not (eq system-type 'android))
      `(use-package ,name ,@plist)))

(defmacro use-package-mobile! (name &rest plist)
  "declares mobile-exclusive packages, this is to save me the hassle of using
control flow"
  (declare (indent 1))
  (if (eq system-type 'android)
      `(use-package ,name ,@plist)))

;; some utility functions that are useful outside of config
(defun read-lines-from-file (filepath)
  "return a list of lines of a file at filepath."
  (interactive "ffile: ")
  (with-temp-buffer
    (insert-file-contents filepath)
    (split-string (buffer-string) "\n" t)))
;; the same function but just to read the entire file as a single string
(defun read-string-from-file (filepath)
  "return the contents of a file as a string"
  (interactive "ffile: ")
  (with-temp-buffer
    (insert-file-contents filepath)
    (buffer-string)))

;; alongside other problems caused by android, we have to make sure the home
;; directory for the rest of our config actually points to the files on both
;; desktop and mobile. android's general home folder is stored at
;;`/storage/emulated/0', when the `~' folder in android emacs is set to
;;`/data/data/org.gnu.emacs/files'. so we create an `agnostic-home-dir'
;; variable to concatenate with a relative path to home.
(if (eq system-type 'android)
    (setq agnostic-home-dir "/storage/emulated/0")
  (setq agnostic-home-dir "~"))

;; configure emacs
(use-package emacs
  :custom
  (use-short-answers t)
  (visible-bell t)
  (history-length 25)
  (global-auto-revert-non-file-buffers t)
  (custom-safe-themes t)
  (inhibit-startup-message t)
  (initial-buffer-choice 'dashboard-open)
  (backup-directory-alist '(("." . "~/.config/emacs/backups")))
  (enable-recursive-minibuffers t)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  :config
  (savehist-mode 1)
  (save-place-mode 1)
  (global-auto-revert-mode 1)
  (global-visual-line-mode 1)
  (global-display-line-numbers-mode 1)
  (repeat-mode 1)
  (dolist (mode '(org-mode-hook term-mode-hook eshell-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode -1))))
  (add-hook 'before-save-hook 'check-parens)
  (add-hook 'prog-mode-hook 'display-fill-column-indicator-mode)
  (recentf-mode 1)
  (make-directory "~/.config/emacs/backups" t)
  (which-key-mode 1)
  (which-key-setup-side-window-bottom)
  (toggle-debug-on-error)
  (if (not (eq system-type 'android))
      (progn
	(setq scroll-conservatively 101	    	    
	      use-dialog-box nil)
	(menu-bar-mode -1)
	(tool-bar-mode -1)
	(scroll-bar-mode -1)
	(when (member "FantasqueSansM Nerd Font Mono" (font-family-list))
	  (set-face-attribute 'default nil
			      :family "FantasqueSansM Nerd Font Mono"
			      :height 120
			      :weight 'regular))
	(when (member "Source Sans Pro" (font-family-list))
	  (set-face-attribute 'variable-pitch nil
			      :family "Source Sans Pro"
			      :height 180)))
    (progn
      (setq use-dialog-box t	     
	    tool-bar-position 'bottom)
      (set-common-vars)
      (modifier-bar-mode 1)
      (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
      (package-initialize)
      (menu-bar-mode 1)))
  :bind
  (("C-x C-b" . ibuffer)
   ("C-c w l" . windmove-right)
   ("C-c w k" . windmove-up)
   ("C-c w j" . windmove-down)
   ("C-c w h" . windmove-left)
   ("C-h k"   . describe-keymap)))

;; config of pre-installed emacs packages
(use-package org
  :custom
  (diary-file
   (concat agnostic-home-dir "/Documents/org/diary.org"))
  (org-directory (concat agnostic-home-dir "/Documents/org/"))
  (org-agenda-files
   (directory-files-recursively
    (concat agnostic-home-dir "/Documents/org/") "\\.org$"))
  (org-agenda-start-with-log-mode t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-adapt-indentation t)
  (org-hide-leading-stars t)
  (org-pretty-entities t)
  (org-todo-keywords
   '((sequence
      "TODO" "PROJ" "READ" "CHECK" "IDEA" ; Needs further action
      "|"
      "DONE")))
  (org-todo-keyword-faces
   '(("TODO"      :inherit (org-todo region) :foreground "#A3BE8C" :weight bold)
     ("PROJ"      :inherit (org-todo region) :foreground "#88C0D0" :weight bold)
     ("READ"      :inherit (org-todo region) :foreground "#8FBCBB" :weight bold)
     ("CHECK"     :inherit (org-todo region) :foreground "#81A1C1" :weight bold)
     ("IDEA"      :inherit (org-todo region) :foreground "#EBCB8B" :weight bold)
     ("DONE"      :inherit (org-todo region) :foreground "#30343d" :weight bold)))
  (org-ellipsis " ·")
  (org-refile-targets
   `(("archive.org" :maxlevel . 1)))
  :config
  (advice-add 'org-refile :after 'org-save-all-org-buffers))

(add-hook 'org-mode-hook 'org-indent-mode)

(use-package-ensure! modus-themes
  :custom
  (modus-vivendi-palette-overrides
      '((bg-main "#242424")
	(bg-dim "#231e1f")
	(fg-main "#dfe6e4")
	(fg-dim "#b9bfbd")
	(fg-alt "#bde9db")))
    (modus-themes-mixed-fonts t)
    (modus-themes-syntax '(faint))
    (modus-themes-variable-pitch-ui t)
    (modus-themes-headings
	  '((1 . (variable-pitch 1.3))
	    (2 . (variable-pitch semibold 1.28))
	    (3 . (variable-pitch medium 1.24))
	    (4 . (variable-pitch regular 1.2))
	    (agenda-date . (1.3))
	    (agenda-structure . (variable-pitch light 1.4))
	    (t . (1.0))))
    :config
    (load-theme 'modus-vivendi t))

;; install new packages and config them
;; discoverability packages
;;emacs, now more self-documenting
(use-package-ensure! helpful
  :bind (("C-h f" . helpful-callable)
	 ("C-h v" . helpful-variable)
 	 ("C-h k" . helpful-key)
 	 ("C-h x" . helpful-command)
 	 ("C-h C-d" . helpful-at-point)))

;; orderless completion style for looser completions when needed
(use-package-ensure! orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file
				    (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;; context windows with keyboard shortcuts
(use-package-ensure! embark
  :bind
  (("C-," . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: m-.
   ("C-h b" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; show the embark target at point via eldoc. you may adjust the
  ;; eldoc strategy, if you want to see the documentation from
  ;; multiple providers. beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  ;; add embark to the mouse context menu. also enable `context-menu-mode'.
  ;; (context-menu-mode 1)
  ;; (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config
  ;; hide the mode line of the embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*embark collect \\(live\\|completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; consult users will also want the embark-consult package.
(use-package-ensure! embark-consult) ; only need to install it, embark loads it after consult if found

(use-package-ensure! vertico
  :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  ;; (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

;; example configuration for consult
(use-package-ensure! consult
  ;; replace bindings. lazily loaded by `use-package'.
  :bind (;; c-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap info-search] . consult-info)
         ;; c-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; custom m-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; m-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g m-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g i" . consult-imenu-multi)
         ;; m-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s g" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s l" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s l" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; the :init configuration is always executed (not lazy)
  :init

  ;; tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  this improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; use consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; optionally configure preview. the default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "m-.")
  ;; (setq consult-preview-key '("s-<down>" "s-<up>"))
  ;; for some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "m-."
   :preview-key '(:debounce 0.4 any))

  ;; optionally configure the narrowing key.
  ;; both < and c-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "c-+"

  ;; optionally make narrowing help available in the minibuffer.
  ;; you may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
)

(use-package-ensure! marginalia
  :bind (:map minibuffer-local-map
	      ("M-a" . marginalia-cycle))
  :init (marginalia-mode))

;; popup window for autocompletions
(use-package-ensure! corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  :init (global-corfu-mode))

(use-package-ensure! rainbow-delimiters
  :hook (prog-mode-hook . rainbow-delimiters-mode))

(use-package-ensure! hl-todo
  :config (global-hl-todo-mode))

;; editing ergonomics
(use-package-ensure! evil
  :config
  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line))

(use-package-ensure! evil-collection
  :config (evil-collection-init))

;; would probably rather use project.el but dashboard only supports projectile
;; afaik
(use-package-ensure! projectile
  :config
  (projectile-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package-ensure! smartparens
  :config
  (require 'smartparens-config)
  :hook
  ((prog-mode text-mode markdown-mode org-mode) . smartparens-mode))

;; eye-candy
;; org-mode prettification
(use-package-ensure! org-superstar
  :custom
  (org-superstar-leading-bullet " ")
  (org-superstar-special-todo-items t) ;; Makes TODO header bullets into boxes
  (org-superstar-headline-bullets-list '("◉" "○" "⚬" "◈" "◇"))
  (org-superstar-prettify-item-bullets nil)
  (org-superstar-special-todo-items t)
  (org-superstar-todo-bullet-alist '(("TODO" . 9744)
                                          ("DONE" . 9744)
                                          ("READ" . 9744)
                                          ("IDEA" . 9744)
                                          ("WAITING" . 9744)
                                          ("CANCELLED" . 9744)
                                          ("PROJECT" . 9744)
                                          ("POSTPONED" . 9744)))
  :hook (org-mode . org-superstar-mode))

(use-package-ensure! org-appear
  :hook (org-mode . org-appear-mode))

(use-package-ensure! org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; Centered editing of org documents, when no other windows are
;; visible
(use-package-ensure! darkroom
  :hook (org-mode . darkroom-tentative-mode))

(use-package-ensure! mixed-pitch
  :hook
  (org-mode . mixed-pitch-mode))

;; (use-package-ensure! org-modern
;;   :hook (org-mode . global-org-modern-mode))

(use-package-ensure! spacious-padding
  :config
  (setq spacious-padding-widths
        '( :internal-border-width 15
           :header-line-width 4
           :mode-line-width 6
           :custom-button-width 3
           :tab-width 4
           :right-divider-width 30
           :scroll-bar-width 8
           :fringe-width 8))
  (spacious-padding-mode 1))

;; configure dependency for doom-modeline
(use-package-ensure! nerd-icons
  :custom
  (nerd-icons-scale-factor 0.75)
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

;; dependency for dashboard (and anything else that has page breaks)
;; so we display them as clean lines
(use-package-ensure! page-break-lines
  :config (global-page-break-lines-mode))

(use-package-ensure! dashboard
  :custom
  (dashboard-display-icons-p t)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-items '((projects . 5)
		     (bookmarks . 5)
		     (recents . 5)
		     (agenda . 5)))
  (dasboard-display-icons-p t)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-center-content t)
  (dashboard-page-separator "\n\f\n")
  (dashboard-image-banner-max-height 240)
  (dashboard-projects-switch-function 'projectile-switch-project-by-name)
  (dashboard-startup-banner (cons "~/.config/emacs/splash/emacs-logo.png" "~/.config/emacs/splash/emacs-logo.txt"))
  :config (dashboard-setup-startup-hook))

(use-package-ensure! doom-modeline
  :custom
  (doom-modeline-spc-face-overrides
   (list :family (face-attribute 'fixed-pitch :family)))
  (doom-modeline-enable-buffer-position nil)
  (doom-modeline-time t)
  (doom-modeline-height 24)
  (doom-modeline-icon t)
  :hook (spacious-padding-mode . doom-modeline-mode))

;; format specific major modes
(use-package-ensure! markdown-mode
  :mode ("readme\\.md\\'" . gfm-mode)
  :custom (markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
         ("C-c C-e" . markdown-do)))

;; desktop-only packages
;; using git on android emacs isn't really practical, and i don't know how to
;; do it with the android build of emacs. it would probably be possible through
;; termux though.
(use-package-desktop! magit
  :straight t
  :defer t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package-desktop! dap-mode
  :straight t)

;; ;; android has pdf viewers that work better on that platform.
(use-package-desktop! pdf-tools
  :straight t
  :defer t
  :magic ("%pdf" . pdf-view-mode)
  :config (pdf-tools-install :no-query))

;; Why is this going over max-eval-depth
;; (use-package-desktop! dap-mode
;;   :straight t)

(use-package-ensure! simple-httpd)

;; for cask dependencies
;;(require 'cask "/Users/nbeydon/.cask/cask.el")
;;(cask-initialize)

;;emacs config
(remove-hook 'kill-buffer-query-functions 'server-kill-buffer-query-function)

;; package section
(package-initialize) (add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/use-package/")
(require 'use-package)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/") ("melpa" . "http://melpa.org/packages/")))
;;#################################################################
;;             My Space Emacs config
;;##################################################################
;; type space for anything
;; nemotechnique

;;#################################################################
;;             EVIL
;;##################################################################

;; comments
;; (evil-commentary-mode)

;; multicursor for evil
(add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/evil-mc/")
(require 'evil-mc)
(global-evil-mc-mode  1) ;; enable

;; leader for evil
(add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/evil-leader/")
(require 'evil-leader)
(global-evil-leader-mode)
(evil-leader/set-leader "<SPC>")

(evil-leader/set-key "w o" 'delete-other-windows)
(evil-leader/set-key "w w" 'other-window)

;; q quit
(evil-leader/set-key "q s" 'save-buffers-kill-emacs)
(evil-leader/set-key "q q" 'kill-emacs)

;; b buffer
(evil-leader/set-key "b <left>" 'tabbar-backward)
(evil-leader/set-key "b <right>" 'tabbar-forward)
(evil-leader/set-key "b k" 'kill-this-buffer)

;; f file
(evil-leader/set-key "f t" 'direx:jump-to-directory)
(evil-leader/set-key "f s" 'save-buffer)
(evil-leader/set-key "f f" 'fiplr-find-file)
(evil-leader/set-key "f n" 'find-file)

;; selection
(evil-leader/set-key "s a" 'mark-whole-buffer)
(defun select-current-line ()
  "Select the current line"
  (interactive)
  (end-of-line) ; move to end of line
    (set-mark (line-beginning-position)))
(evil-leader/set-key "s l" 'select-current-line)
(evil-leader/set-key "s r" 'expand-region)
(evil-leader/set-key "s n" 'mc/mark-next-like-this)
(evil-leader/set-key "s p" 'mc/mark-previous-like-this)

;; find word
(evil-leader/set-key "F" 'ag)

;;l is linter
(evil-leader/set-key "l l" 'flycheck-list-errors)

(require 'evil)
(evil-mode 1)
;;(define-key evil-normal-state-map "u" 'previous-line)
;;(define-key evil-normal-state-map "j" 'next-line)
;;(define-key evil-normal-state-map "h" 'backward-char)
;;(define-key evil-normal-state-map "k" 'forward-char)

;;#################################################################
;;             sublimity
;;##################################################################
(add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/sublimity/")
(require 'sublimity) (require 'sublimity-scroll) (require 'sublimity-attractive)
(sublimity-mode 1)

;;#################################################################
;;             AG
;;##################################################################
;;(add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/ag/")
(require 'ag)


;;(add-hook 'web-mode-hook  'my-web-mode-hook)

;;#################################################################
;;             linter
;;##################################################################
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

(add-to-list 'load-path "/Users/nbeydon/.emacs.d/cl-lib/")
(require 'cl-lib)

(setq backup-directory-alist `(("." . "~/.saves")))


(defalias 'yes-or-no-p 'y-or-n-p)

(setq mac-command-modifier 'super)

(set-keyboard-coding-system nil)

(add-to-list 'package-archives
  	     '("melpa" . "https://melpa.org/packages/"))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))

;; use web-mode for .jsx files
(add-to-list 'auto-mode-alist '("\\.jsx$" . web-mode))

;; http://www.flycheck.org/manual/latest/index.html
(require 'flycheck)

;; turn on flychecking globally
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
  	      (append flycheck-disabled-checkers
  		      '(javascript-jshint)))

(setq flycheck-disabled-checkers '(javascript-jshint))
(setq flycheck-disabled-checkers '(javascript-jscs))
(setq flycheck-disabled-checkers '(javascript-standard))
(setq flycheck-checkers '(javascript-eslint))

;; use eslint with web-mode for jsx files
(flycheck-add-mode 'javascript-eslint 'web-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".")

;; disable json-jsonlist checking for json files
(setq-default flycheck-disabled-checkers
  	      (append flycheck-disabled-checkers
  		      '(json-jsonlist)))

;; https://github.com/purcell/exec-path-from-shell
;; only need exec-path-from-shell on OSX
;; this hopefully sets up path and other vars better
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

;; adjust indents for web-mode to 4 spaces
(defun my-web-mode-hook ()
  "Hooks for Web mode. Adjust indents"
      ;;; http://web-mode.org/
  (setq web-mode-markup-indent-offset 4)
  (setq web-mode-css-indent-offset 4)
  (setq web-mode-code-indent-offset 4))
(add-hook 'web-mode-hook  'my-web-mode-hook)

;; disable tab indent
(setq-default indent-tabs-mode nil)

;; for better jsx syntax-highlighting in web-mode
;; - courtesy of Patrick @halbtuerke
(defadvice web-mode-highlight-part (around tweak-jsx activate)
  (if (equal web-mode-content-type "jsx")
      (let ((web-mode-enable-part-face nil))
  	ad-do-it)
    ad-do-it))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("04dd0236a367865e591927a3810f178e8d33c372ad5bfef48b5ce90d4b476481" "a802c77b818597cc90e10d56e5b66945c57776f036482a033866f5f506257bca" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" "a0feb1322de9e26a4d209d1cfa236deaf64662bb604fa513cca6a057ddf0ef64" "01ce486c3a7c8b37cf13f8c95ca4bb3c11413228b35676025fdf239e77019ea1" default))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(tabbar-button ((t (:inherit tabbar-default :background "#c62d5b" :foreground "#c62d5b"))))
 '(tabbar-button-highlight ((t (:inherit tabbar-default))))
 '(tabbar-default ((t (:inherit variable-pitch :background "#c62d5b" :foreground "#c62d5b" :weight bold))))
 '(tabbar-highlight ((t (:underline t))))
 '(tabbar-selected ((t (:inherit tabbar-default :background "#FC6291" :foreground "white"))))
 '(tabbar-separator ((t (:inherit tabbar-default :background "#D50000"))))
 '(tabbar-unselected ((t (:inherit tabbar-default :background "#c62d5b" :foreground "#DDDDDD")))))

;; tern js
;;(add-to-list 'load-path "/usr/local/lib/node_modules/tern/emacs/")
;;(autoload 'tern-mode "tern.el" nil t)

(setq js2-highlight-level 4)

;;color everywhere <3
(add-hook 'after-init-hook 'global-color-identifiers-mode)

;;config fiplr
(setq fiplr-root-markers '(".git" ".svn"))
(setq fiplr-ignored-globs '((directories (".git" ".svn" "tmp" "node_modules" "coverage" "build" "platforms" ".idea"))
                            (files ("*.jpg" "*.png" "*.zip" "*~"))))

;;change backup directory (stop poluting git repos)
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

(let ((faces '(font-lock-comment-face font-lock-comment-delimiter-face font-lock-constant-face font-lock-type-face font-lock-function-name-face font-lock-variable-name-face font-lock-keyword-face font-lock-string-face font-lock-builtin-face font-lock-preprocessor-face font-lock-warning-face font-lock-doc-face)))
  (dolist (face faces)
    (set-face-attribute face nil :foreground nil :weight 'normal :slant 'normal)))

(set-face-attribute 'font-lock-comment-delimiter-face nil :slant 'italic)
(set-face-attribute 'font-lock-comment-face nil :slant 'italic)
(set-face-attribute 'font-lock-doc-face nil :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil :weight 'bold)
(set-face-attribute 'font-lock-builtin-face nil :weight 'bold)
(set-face-attribute 'font-lock-preprocessor-face nil :weight 'bold)

;;autocomplete
(ac-config-default)
(setq ac-ignore-case nil)

;; add a line
(require 'whitespace)
(setq whitespace-line-column 100) ;; limit line length
(setq whitespace-style '(face lines-tail))

(add-hook 'prog-mode-hook 'whitespace-mode)

;;override the selection instead of writing around
(delete-selection-mode 1)

;;treat .tpl files as html-mode
(add-to-list 'auto-mode-alist '("\\.tpl\\'" . web-mode))

;;utf8 !
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

;;when fleme on
(require 'mouse)
(xterm-mouse-mode t)
(defun track-mouse (e))
(setq mouse-sel-mode t)

;; show start and end for ( [
;;(show-paren-mode 1)

;; wrap a region
(require 'smartparens-config)
(add-hook 'web-mode #'smartparens-mode)

(wrap-region-global-mode t)
;;(add-hook 'web-mode #'wrap-region-mode)

;;alway enable line numbers
;;(global-linum-mode 1)
;;(setq linum-format "%d | ")

;;#################################################################
;;             tabs
;;##################################################################
(require 'tabbar)

(defun my-tabbar-buffer-groups () ;; customize to show all normal files in one group
  "Returns the name of the tab group names the current buffer belongs to.
 There are two groups: Emacs buffers (those whose name starts with '*', plus
 dired buffers), and the rest.  This works at least with Emacs v24.2 using
 tabbar.el v1.7."
  (list (cond ((string-equal "*" (substring (buffer-name) 0 1)) "emacs")
              ((eq major-mode 'dired-mode) "emacs")
              (t "user"))))
(setq tabbar-buffer-groups-function 'my-tabbar-buffer-groups)

(setq tabbar-background-color "#c62d5b") ;; the color of the tabbar background

(setq tabbar-cycle-scope (quote tabs))
(setq tabbar-use-images t)
;; BUFFER MODIFICATION STATE INDICATOR
(defadvice tabbar-buffer-tab-label (after fixup_tab_label_space_and_flag activate)
  (setq ad-return-value
        (if (and (buffer-modified-p (tabbar-tab-value tab))
                 (buffer-file-name (tabbar-tab-value tab)))
            (concat " + " (concat ad-return-value " "))
          (concat " " (concat ad-return-value " ")))))
(defun ztl-modification-state-change ()
  (tabbar-set-template tabbar-current-tabset nil)
  (tabbar-display-update))
(defun ztl-on-buffer-modification ()
  (set-buffer-modified-p t)
  (ztl-modification-state-change))
(add-hook 'after-save-hook 'ztl-modification-state-change)
(add-hook 'first-change-hook 'ztl-on-buffer-modification)
(tabbar-mode)

;;disable menu-bar
(menu-bar-mode -1)

;;#################################################################
;;             nice footer bar
;;##################################################################
;;(add-to-list 'load-path "/Users/nbeydon/.emacs.d/vendor/emacs-powerline")
;;(require 'powerline)
;;(setq powerline-arrow-shape 'arrow)   ;; the default
;;(setq powerline-arrow-shape 'curve)   ;; give your mode-line curves
;;(setq powerline-arrow-shape 'arrow14) ;; best for small fonts

;; These two lines you really need.
;;(set-face-attribute 'mode-line nil
;;                    :foreground "Black"
;;                    :background "DarkOrange"
;;                    :box nil)
;;(setq powerline-arrow-shape 'arrow14) ;; best for small fonts
(setq sml/theme 'powerline)
(sml/setup)
(setq sml/no-confirm-load-theme t)

;;#################################################################
;;             Echap to kill action
;;##################################################################
;; esc quits
(defun minibuffer-keyboard-quit ()
    "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
    (interactive)
    (if (and delete-selection-mode transient-mark-mode mark-active)
        (setq deactivate-mark  t)
      (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
      (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

;; dont move back cursor
(setq evil-move-cursor-back nil)

;;#################################################################
;;             keymap
;;##################################################################
;; navigate between tabs
(global-set-key [C-left] 'tabbar-backward)
(global-set-key [C-right] 'tabbar-forward)
;; kill buffer
(global-set-key (kbd "C-x C-j") 'direx:jump-to-directory)

(defun pbcopy ()
  (interactive)
  (call-process-region (point) (mark) "pbcopy")
  (setq deactivate-mark t))

(defun pbpaste ()
  (interactive)
  (call-process-region (point) (if mark-active (mark) (point)) "pbpaste" t t))

(defun pbcut ()
  (interactive)
  (pbcopy)
  (delete-region (region-beginning) (region-end)))

(global-set-key (kbd "<f13> c") 'pbcopy)
(global-set-key (kbd "<f13> v") 'pbpaste)
(define-key evil-normal-state-map (kbd "<f13> v") #'pbpaste)
(global-set-key (kbd "<f13> x") 'pbcut)

(global-set-key (kbd "<f13> z") 'fiplr-find-file)
(eval-after-load 'evil-ex
    '(evil-ex-define-cmd "f[uzzy]" 'fiplr-find-file))
;;expend-region
(require 'expand-region)
(global-set-key (kbd "C-d") 'er/expand-region)

;;expend-line
(global-set-key (kbd "C-l") 'turn-on-expand-line-mode)

;;multiline-cursors
(require 'multiple-cursors)
(global-set-key (kbd "C-x C-d") 'mc/mark-next-like-this)

(global-set-key (kbd "M-Q") 'kill-emacs)
(global-set-key (kbd "C-z") 'undo)
(global-set-key (kbd "C-y") 'redo)

;;(global-set-key (kbd "C-u") 'previous-line)
;;(global-set-key (kbd "C-j") 'next-line)
;;(global-set-key (kbd "C-h") 'evil-window-left)
;;(global-set-key (kbd "C-k") 'evil-window-right)
;;

(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init (setq markdown-command "multimarkdown"))

(add-hook 'gfm-mode-hook 'writeroom-mode)

(setq mc/cmds-to-run-for-all
      '(
        evil-append-line
        evil-backward-WORD-begin
        evil-backward-word-begin
        evil-delete-char
        evil-delete-line
        evil-digit-argument-or-evil-beginning-of-line
        evil-emacs-state
        evil-end-of-line
        evil-force-normal-state
        evil-forward-WORD-begin
        evil-forward-WORD-end
        evil-forward-word-begin
        evil-forward-word-end
        evil-insert
        evil-next-line
        evil-normal-state
        evil-previous-line
                ))

;; add highlighting for jade files
(require 'sws-mode)
(require 'jade-mode)
(add-to-list 'auto-mode-alist '("\\.styl\\'" . sws-mode))

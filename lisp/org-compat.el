;;; org-compat.el --- Compatibility Code for Older Emacsen -*- lexical-binding: t; -*-

;; Copyright (C) 2004-2016 Free Software Foundation, Inc.

;; Author: Carsten Dominik <carsten at orgmode dot org>
;; Keywords: outlines, hypermedia, calendar, wp
;; Homepage: http://orgmode.org
;;
;; This file is part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; This file contains code needed for compatibility with older
;; versions of GNU Emacs.

;;; Code:

(require 'cl-lib)
(require 'org-macs)

(declare-function org-at-table.el-p "org" (&optional table-type))
(declare-function org-element-at-point "org-element" ())
(declare-function org-element-type "org-element" (element))
(declare-function org-link-set-parameters "org" (type &rest rest))
(declare-function org-table-end (&optional table-type))
(declare-function table--at-cell-p "table" (position &optional object at-column))

(defvar org-table-any-border-regexp)
(defvar org-table-dataline-regexp)
(defvar org-table-tab-recognizes-table.el)
(defvar org-table1-hline-regexp)

;; As of Emacs 25.1, `outline-mode' functions are under the 'outline-'
;; prefix, `find-tag' is replaced with `xref-find-definition' and
;; `x-get-selection' with `gui-get-selection'.
(when (< emacs-major-version 25)
  (defalias 'outline-hide-entry 'hide-entry)
  (defalias 'outline-hide-sublevels 'hide-sublevels)
  (defalias 'outline-hide-subtree 'hide-subtree)
  (defalias 'outline-show-all 'show-all)
  (defalias 'outline-show-branches 'show-branches)
  (defalias 'outline-show-children 'show-children)
  (defalias 'outline-show-entry 'show-entry)
  (defalias 'outline-show-subtree 'show-subtree)
  (defalias 'xref-find-definitions 'find-tag)
  (defalias 'format-message 'format)
  (defalias 'gui-get-selection 'x-get-selection))


;;; Obsolete aliases (remove them once the next major release is released).

;;;; XEmacs compatibility, now removed.
(define-obsolete-function-alias 'org-activate-mark 'activate-mark)
(define-obsolete-function-alias 'org-add-hook 'add-hook "Org 9.0")
(define-obsolete-function-alias 'org-bound-and-true-p 'bound-and-true-p "Org 9.0")
(define-obsolete-function-alias 'org-decompose-region 'decompose-region "Org 9.0")
(define-obsolete-function-alias 'org-defvaralias 'defvaralias "Org 9.0")
(define-obsolete-function-alias 'org-detach-overlay 'delete-overlay "Org 9.0")
(define-obsolete-function-alias 'org-file-equal-p 'file-equal-p "Org 9.0")
(define-obsolete-function-alias 'org-float-time 'float-time "Org 9.0")
(define-obsolete-function-alias 'org-indent-line-to 'indent-line-to "Org 9.0")
(define-obsolete-function-alias 'org-indent-to-column 'indent-to-column "Org 9.0")
(define-obsolete-function-alias 'org-looking-at-p 'looking-at-p "Org 9.0")
(define-obsolete-function-alias 'org-looking-back 'looking-back "Org 9.0")
(define-obsolete-function-alias 'org-match-string-no-properties 'match-string-no-properties "Org 9.0")
(define-obsolete-function-alias 'org-propertize 'propertize "Org 9.0")
(define-obsolete-function-alias 'org-select-frame-set-input-focus 'select-frame-set-input-focus "Org 9.0")

(defmacro org-re (s)
  "Replace posix classes in regular expression S."
  (declare (debug (form))
	   (obsolete "you can safely remove it." "Org 9.0"))
  s)

;;;; Functions from cl-lib that Org used to have its own implementation of.
(define-obsolete-function-alias 'org-count 'cl-count "Org 9.0")
(define-obsolete-function-alias 'org-every 'cl-every "Org 9.0")
(define-obsolete-function-alias 'org-find-if 'cl-find-if "Org 9.0")
(define-obsolete-function-alias 'org-reduce 'cl-reduce "Org 9.0")
(define-obsolete-function-alias 'org-remove-if 'cl-remove-if "Org 9.0")
(define-obsolete-function-alias 'org-remove-if-not 'cl-remove-if-not "Org 9.0")
(define-obsolete-function-alias 'org-some 'cl-some "Org 9.0")
(define-obsolete-function-alias 'org-floor* 'cl-floor "Org 9.0")

(defun org-sublist (list start end)
  "Return a section of LIST, from START to END.
Counting starts at 1."
  (cl-subseq list (1- start) end))
(make-obsolete 'org-sublist
	       "use cl-subseq (note the 0-based counting)."
	       "Org 9.0")


;;;; Functions available since Emacs 24.3
(define-obsolete-function-alias 'org-buffer-narrowed-p 'buffer-narrowed-p "Org 9.0")
(define-obsolete-function-alias 'org-called-interactively-p 'called-interactively-p "Org 9.0")
(define-obsolete-function-alias 'org-char-to-string 'char-to-string "Org 9.0")
(define-obsolete-function-alias 'org-delete-directory 'delete-directory "Org 9.0")
(define-obsolete-function-alias 'org-format-seconds 'format-seconds "Org 9.0")
(define-obsolete-function-alias 'org-link-escape-browser 'url-encode-url "Org 9.0")
(define-obsolete-function-alias 'org-no-warnings 'with-no-warnings "Org 9.0")
(define-obsolete-function-alias 'org-number-sequence 'number-sequence "Org 9.0")
(define-obsolete-function-alias 'org-pop-to-buffer-same-window 'pop-to-buffer-same-window "Org 9.0")
(define-obsolete-function-alias 'org-string-match-p 'string-match-p "Org 9.0")

;;;; Functions and variables from previous releases now obsolete.
(define-obsolete-function-alias 'org-element-remove-indentation
  'org-remove-indentation "Org 9.0")
(define-obsolete-variable-alias 'org-hierarchical-checkbox-statistics
  'org-checkbox-hierarchical-statistics "Org 8.0")
(define-obsolete-variable-alias 'org-description-max-indent
  'org-list-description-max-indent "Org 8.0")
(define-obsolete-variable-alias 'org-latex-create-formula-image-program
  'org-preview-latex-default-process "Org 9.0")
(define-obsolete-variable-alias 'org-latex-preview-ltxpng-directory
 'org-preview-latex-image-directory "Org 9.0")
(define-obsolete-function-alias 'org-table-p 'org-at-table-p "Org 9.0")
(define-obsolete-function-alias 'org-on-heading-p 'org-at-heading-p "Org 9.0")
(define-obsolete-function-alias 'org-at-regexp-p 'org-in-regexp "Org 8.3")
(define-obsolete-function-alias 'org-speed-command-default-hook
  'org-speed-command-activate "Org 8.0")
(define-obsolete-function-alias 'org-babel-speed-command-hook
  'org-babel-speed-command-activate "Org 8.0")
(define-obsolete-function-alias 'org-image-file-name-regexp
  'image-file-name-regexp "Org 9.0")
(define-obsolete-function-alias 'org-get-legal-level
  'org-get-valid-level "Org 7.8")
(define-obsolete-function-alias 'org-completing-read-no-i
  'completing-read "Org 9.0")
(define-obsolete-function-alias 'org-icompleting-read
  'completing-read "Org 9.0")
(define-obsolete-function-alias 'org-iread-file-name 'read-file-name "Org 9.0")
(define-obsolete-function-alias 'org-days-to-time
  'org-time-stamp-to-now "Org 8.2")
(define-obsolete-variable-alias 'org-agenda-ignore-drawer-properties
  'org-agenda-ignore-properties "Org 9.0")
(define-obsolete-function-alias 'org-preview-latex-fragment
  'org-toggle-latex-fragment "Org 8.3")
(define-obsolete-function-alias 'org-display-inline-modification-hook
  'org-display-inline-remove-overlay "Org 8.0")
(define-obsolete-function-alias 'org-export-get-genealogy
  'org-element-lineage "Org 9.0")
(define-obsolete-variable-alias 'org-latex-with-hyperref
  'org-latex-hyperref-template "Org 9.0")
(define-obsolete-variable-alias 'org-link-to-org-use-id
  'org-id-link-to-org-use-id "Org 8.0")
(define-obsolete-variable-alias 'hfy-optimisations 'hfy-optimizations "Org 9.0")
(define-obsolete-variable-alias 'org-clock-modeline-total
  'org-clock-mode-line-total "Org 8.0")
(define-obsolete-function-alias 'org-protocol-unhex-compound
  'org-link-unescape-compound "Org 7.8")
(define-obsolete-function-alias 'org-protocol-unhex-string
  'org-link-unescape "Org 7.8")
(define-obsolete-function-alias 'org-protocol-unhex-single-byte-sequence
  'org-link-unescape-single-byte-sequence "Org 7.8")
(define-obsolete-variable-alias 'org-export-htmlized-org-css-url
  'org-org-htmlized-css-url "Org 8.2")
(define-obsolete-variable-alias 'org-alphabetical-lists
  'org-list-allow-alphabetical "Org 8.0")
(define-obsolete-function-alias 'org-list-parse-list 'org-list-to-lisp "Org 9.0")
(define-obsolete-variable-alias 'org-agenda-menu-two-column
  'org-agenda-menu-two-columns "Org 8.0")
(define-obsolete-variable-alias 'org-finalize-agenda-hook
  'org-agenda-finalize-hook "Org 8.0")
(make-obsolete-variable 'org-agenda-ndays 'org-agenda-span "Org 7.8")
(define-obsolete-function-alias 'org-agenda-post-command-hook
  'org-agenda-update-agenda-type "Org 8.0")
(define-obsolete-function-alias 'org-agenda-todayp
  'org-agenda-today-p "Org 9.0")
(define-obsolete-function-alias 'org-babel-examplize-region
  'org-babel-examplify-region "Org 9.0")
(define-obsolete-function-alias 'org-babel-trim 'org-trim "Org 9.0")
(define-obsolete-variable-alias 'org-html-style-include-scripts
  'org-html-head-include-scripts "Org 8.0")
(define-obsolete-variable-alias 'org-html-style-include-default
  'org-html-head-include-default-style "Org 8.0")
(define-obsolete-variable-alias 'org-html-style 'org-html-head "24.4")
(define-obsolete-function-alias 'org-insert-columns-dblock
  'org-columns-insert-dblock "Org 9.0")
(define-obsolete-function-alias 'org-export-babel-evaluate
  'org-export-use-babel "Org 9.1")

(defun org-in-fixed-width-region-p ()
  "Non-nil if point in a fixed-width region."
  (save-match-data
    (eq 'fixed-width (org-element-type (org-element-at-point)))))
(make-obsolete 'org-in-fixed-width-region-p
	       "use `org-element' library"
	       "Org 9.0")

(defcustom org-read-date-minibuffer-setup-hook nil
  "Hook to be used to set up keys for the date/time interface.
Add key definitions to `minibuffer-local-map', which will be a
temporary copy."
  :group 'org-time
  :type 'hook)
(make-obsolete-variable
 'org-read-date-minibuffer-setup-hook
 "set `org-read-date-minibuffer-local-map' instead." "Org 8.0")

(defun org-compatible-face (inherits specs)
  "Make a compatible face specification.
If INHERITS is an existing face and if the Emacs version supports
it, just inherit the face.  If INHERITS is not given and SPECS
is, use SPECS to define the face."
  (declare (indent 1))
  (if (facep inherits)
      (list (list t :inherit inherits))
    specs))
(make-obsolete 'org-compatible-face "you can remove it." "Org 9.0")

(defun org-add-link-type (type &optional follow export)
  "Add a new TYPE link.
FOLLOW and EXPORT are two functions.

FOLLOW should take the link path as the single argument and do whatever
is necessary to follow the link, for example find a file or display
a mail message.

EXPORT should format the link path for export to one of the export formats.
It should be a function accepting three arguments:

  path    the path of the link, the text after the prefix (like \"http:\")
  desc    the description of the link, if any
  format  the export format, a symbol like `html' or `latex' or `ascii'.

The function may use the FORMAT information to return different values
depending on the format.  The return value will be put literally into
the exported file.  If the return value is nil, this means Org should
do what it normally does with links which do not have EXPORT defined.

Org mode has a built-in default for exporting links.  If you are happy with
this default, there is no need to define an export function for the link
type.  For a simple example of an export function, see `org-bbdb.el'.

If TYPE already exists, update it with the arguments.
See `org-link-parameters' for documentation on the other parameters."
  (org-link-set-parameters type :follow follow :export export)
  (message "Created %s link." type))

(make-obsolete 'org-add-link-type "use `org-link-set-parameters' instead." "Org 9.0")

(defun org-table-recognize-table.el ()
  "If there is a table.el table nearby, recognize it and move into it."
  (when (and org-table-tab-recognizes-table.el (org-at-table.el-p))
    (beginning-of-line)
    (unless (or (looking-at org-table-dataline-regexp)
		(not (looking-at org-table1-hline-regexp)))
      (forward-line)
      (when (looking-at org-table-any-border-regexp)
	(forward-line -2)))
    (if (re-search-forward "|" (org-table-end t) t)
	(progn
	  (require 'table)
	  (if (table--at-cell-p (point)) t
	    (message "recognizing table.el table...")
	    (table-recognize-table)
	    (message "recognizing table.el table...done")))
      (error "This should not happen"))))

;; Not used by Org core since commit 6d1e3082, Feb 2010.
(make-obsolete 'org-table-recognize-table.el
	       "please notify the org mailing list if you use this function."
	       "Org 9.0")

(define-obsolete-function-alias
  'org-minutes-to-hh:mm-string 'org-minutes-to-clocksum-string "Org 8.0")

(defun org-remove-angle-brackets (s)
  (org-unbracket-string "<" ">" s))
(make-obsolete 'org-remove-angle-brackets 'org-unbracket-string "Org 9.0")

(defun org-remove-double-quotes (s)
  (org-unbracket-string "\"" "\"" s))
(make-obsolete 'org-remove-double-quotes 'org-unbracket-string "Org 9.0")

;;;; Obsolete link types

(eval-after-load 'org
  '(progn
     (org-link-set-parameters "file+emacs") ;since Org 9.0
     (org-link-set-parameters "file+sys"))) ;since Org 9.0



;;; Miscellaneous functions

(defun org-version-check (version feature level)
  (let* ((v1 (mapcar 'string-to-number (split-string version "[.]")))
	 (v2 (mapcar 'string-to-number (split-string emacs-version "[.]")))
	 (rmaj (or (nth 0 v1) 99))
	 (rmin (or (nth 1 v1) 99))
	 (rbld (or (nth 2 v1) 99))
	 (maj (or (nth 0 v2) 0))
	 (min (or (nth 1 v2) 0))
	 (bld (or (nth 2 v2) 0)))
    (if (or (< maj rmaj)
	    (and (= maj rmaj)
		 (< min rmin))
	    (and (= maj rmaj)
		 (= min rmin)
		 (< bld rbld)))
	(if (eq level :predicate)
	    ;; just return if we have the version
	    nil
	  (let ((msg (format "Emacs %s or greater is recommended for %s"
			     version feature)))
	    (display-warning 'org msg level)
	    t))
      t)))

(defun org-get-x-clipboard (value)
  "Get the value of the X or Windows clipboard."
  (cond ((and (eq window-system 'x)
	      (fboundp 'gui-get-selection)) ;Silence byte-compiler.
	 (org-no-properties
	  (ignore-errors
	    (or (gui-get-selection value 'UTF8_STRING)
		(gui-get-selection value 'COMPOUND_TEXT)
		(gui-get-selection value 'STRING)
		(gui-get-selection value 'TEXT)))))
	((and (eq window-system 'w32) (fboundp 'w32-get-clipboard-data))
	 (w32-get-clipboard-data))))

(defun org-add-props (string plist &rest props)
  "Add text properties to entire string, from beginning to end.
PLIST may be a list of properties, PROPS are individual properties and values
that will be added to PLIST.  Returns the string that was modified."
  (add-text-properties
   0 (length string) (if props (append plist props) plist) string)
  string)
(put 'org-add-props 'lisp-indent-function 2)

(defun org-fit-window-to-buffer (&optional window max-height min-height
					   shrink-only)
  "Fit WINDOW to the buffer, but only if it is not a side-by-side window.
WINDOW defaults to the selected window.  MAX-HEIGHT and MIN-HEIGHT are
passed through to `fit-window-to-buffer'.  If SHRINK-ONLY is set, call
`shrink-window-if-larger-than-buffer' instead, the height limit is
ignored in this case."
  (cond ((if (fboundp 'window-full-width-p)
	     (not (window-full-width-p window))
	   ;; do nothing if another window would suffer
	   (> (frame-width) (window-width window))))
	((and (fboundp 'fit-window-to-buffer) (not shrink-only))
	 (fit-window-to-buffer window max-height min-height))
	((fboundp 'shrink-window-if-larger-than-buffer)
	 (shrink-window-if-larger-than-buffer window)))
  (or window (selected-window)))

;; `set-transient-map' is only in Emacs >= 24.4
(defalias 'org-set-transient-map
  (if (fboundp 'set-transient-map)
      'set-transient-map
    'set-temporary-overlay-map))

;;; Region compatibility

(defvar org-ignore-region nil
  "Non-nil means temporarily disable the active region.")

(defun org-region-active-p ()
  "Non-nil when the region active.
Unlike to `use-region-p', this function also checks
`org-ignore-region'."
  (and (not org-ignore-region) (use-region-p)))

(defun org-cursor-to-region-beginning ()
  (when (and (org-region-active-p)
	     (> (point) (region-beginning)))
    (exchange-point-and-mark)))

;;; Invisibility compatibility

(defun org-remove-from-invisibility-spec (arg)
  "Remove elements from `buffer-invisibility-spec'."
  (if (fboundp 'remove-from-invisibility-spec)
      (remove-from-invisibility-spec arg)
    (if (consp buffer-invisibility-spec)
	(setq buffer-invisibility-spec
	      (delete arg buffer-invisibility-spec)))))

(defun org-in-invisibility-spec-p (arg)
  "Is ARG a member of `buffer-invisibility-spec'?"
  (if (consp buffer-invisibility-spec)
      (member arg buffer-invisibility-spec)))

(defun org-move-to-column (column &optional force _buffer)
  "Move to column COLUMN.
Pass COLUMN and FORCE to `move-to-column'."
  (let ((buffer-invisibility-spec
	 (if (listp buffer-invisibility-spec)
	     (remove '(org-filtered) buffer-invisibility-spec)
	   buffer-invisibility-spec)))
    (move-to-column column force)))

(defmacro org-find-library-dir (library)
  `(file-name-directory (or (locate-library ,library) "")))

(defun org-count-lines (s)
  "How many lines in string S?"
  (let ((start 0) (n 1))
    (while (string-match "\n" s start)
      (setq start (match-end 0) n (1+ n)))
    (if (and (> (length s) 0) (= (aref s (1- (length s))) ?\n))
	(setq n (1- n)))
    n))

(defun org-kill-new (string &rest args)
  (remove-text-properties 0 (length string) '(line-prefix t wrap-prefix t)
			  string)
  (apply 'kill-new string args))

;; `font-lock-ensure' is only available from 24.4.50 on
(defalias 'org-font-lock-ensure
  (if (fboundp 'font-lock-ensure)
      #'font-lock-ensure
    (lambda (&optional _beg _end)
      (with-no-warnings (font-lock-fontify-buffer)))))

(defmacro org-no-popups (&rest body)
  "Suppress popup windows.
Let-bind some variables to nil around BODY to achieve the desired
effect, which variables to use depends on the Emacs version."
  (if (org-version-check "24.2.50" "" :predicate)
      `(let (pop-up-frames display-buffer-alist)
	 ,@body)
    `(let (pop-up-frames special-display-buffer-names special-display-regexps special-display-function)
       ,@body)))

;;;###autoload
(defmacro org-check-version ()
  "Try very hard to provide sensible version strings."
  (let* ((org-dir        (org-find-library-dir "org"))
	 (org-version.el (concat org-dir "org-version.el"))
	 (org-fixup.el   (concat org-dir "../mk/org-fixup.el")))
    (if (require 'org-version org-version.el 'noerror)
	'(progn
	   (autoload 'org-release     "org-version.el")
	   (autoload 'org-git-version "org-version.el"))
      (if (require 'org-fixup org-fixup.el 'noerror)
	  '(org-fixup)
	;; provide fallback definitions and complain
	(warn "Could not define org version correctly.  Check installation!")
	'(progn
	   (defun org-release () "N/A")
	   (defun org-git-version () "N/A !!check installation!!"))))))

(defmacro org-with-silent-modifications (&rest body)
  (if (fboundp 'with-silent-modifications)
      `(with-silent-modifications ,@body)
    `(org-unmodified ,@body)))
(def-edebug-spec org-with-silent-modifications (body))

;; Functions for Emacs < 24.4 compatibility
(defun org-define-error (name message)
  "Define NAME as a new error signal.
MESSAGE is a string that will be output to the echo area if such
an error is signaled without being caught by a `condition-case'.
Implements `define-error' for older emacsen."
  (if (fboundp 'define-error) (define-error name message)
    (put name 'error-conditions
	 (copy-sequence (cons name (get 'error 'error-conditions))))))

(unless (fboundp 'string-suffix-p)
  ;; From Emacs subr.el.
  (defun string-suffix-p (suffix string  &optional ignore-case)
    "Return non-nil if SUFFIX is a suffix of STRING.
If IGNORE-CASE is non-nil, the comparison is done without paying
attention to case differences."
    (let ((start-pos (- (length string) (length suffix))))
      (and (>= start-pos 0)
	   (eq t (compare-strings suffix nil nil
				  string start-pos nil ignore-case))))))

(provide 'org-compat)

;;; org-compat.el ends here

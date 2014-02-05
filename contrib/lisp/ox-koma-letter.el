;;; ox-koma-letter.el --- KOMA Scrlttr2 Back-End for Org Export Engine

;; Copyright (C) 2007-2012, 2014  Free Software Foundation, Inc.

;; Author: Nicolas Goaziou <n.goaziou AT gmail DOT com>
;;         Alan Schmitt <alan.schmitt AT polytechnique DOT org>
;;         Viktor Rosenfeld <listuser36 AT gmail DOT com>
;;         Rasmus Pank Roulund <emacs AT pank DOT eu>
;; Keywords: org, wp, tex

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This library implements a KOMA Scrlttr2 back-end, derived from the
;; LaTeX one.
;;
;; Depending on the desired output format, three commands are provided
;; for export: `org-koma-letter-export-as-latex' (temporary buffer),
;; `org-koma-letter-export-to-latex' ("tex" file) and
;; `org-koma-letter-export-to-pdf' ("pdf" file).
;;
;; On top of buffer keywords supported by `latex' back-end (see
;; `org-latex-options-alist'), this back-end introduces the following
;; keywords:
;;   - CLOSING: see `org-koma-letter-closing',
;;   - FROM_ADDRESS: see `org-koma-letter-from-address',
;;   - LCO: see `org-koma-letter-class-option-file',
;;   - OPENING: see `org-koma-letter-opening',
;;   - PHONE_NUMBER: see `org-koma-letter-phone-number',
;;   - SIGNATURE: see `org-koma-letter-signature',
;;   - PLACE: see `org-koma-letter-place',
;;   - TO_ADDRESS:  If unspecified this is set to "\mbox{}".
;;
;; TO_ADDRESS and FROM_ADDRESS can also be specified using heading
;; with the special tags specified in
;; `org-koma-letter-special-tags-in-letter', namely "to" and "from".
;; LaTeX line breaks are not necessary if using these headings.  If
;; both a headline and a keyword specify a to or from address the
;; value is determined in accordance with
;; `org-koma-letter-prefer-special-headings'.
;;
;; A number of OPTIONS settings can be set to change which contents is
;; exported.
;;   - backaddress (see `org-koma-letter-use-backaddress')
;;   - foldmarks (see `org-koma-letter-use-foldmarks')
;;   - phone (see `org-koma-letter-use-phone')
;;   - email (see `org-koma-letter-use-email')
;;   - place (see `org-koma-letter-use-place')
;;   - subject, a list of format options
;;     (see `org-koma-letter-subject-format')
;;   - after-closing-order, a list of the ordering of headings with
;;     special tags after closing (see
;;     `org-koma-letter-special-tags-after-closing')
;;   - after-letter-order, as above, but after the end of the letter
;;     (see `org-koma-letter-special-tags-after-letter').
;;
;; The following variables works differently from the main LaTeX class
;;   - AUTHOR: Default to user-full-name but may be disabled.
;;     (See also `org-koma-letter-author'),
;;   - EMAIL: Same as AUTHOR. (see also `org-koma-letter-email'),
;;
;; Headlines are in general ignored.  However, headlines with special
;; tags can be used for specified contents like postscript (ps),
;; carbon copy (cc), enclosures (encl) and code to be inserted after
;; \end{letter} (after_letter).  Specials tags are defined in
;; `org-koma-letter-special-tags-after-closing' and
;; `org-koma-letter-special-tags-after-letter'.  Currently members of
;; `org-koma-letter-special-tags-after-closing' used as macros and the
;; content of the headline is the argument.
;;
;; Headlines with two and from may also be used rather than the
;; keyword approach described above.  If both a keyword and a headline
;; with information is present precedence is determined by
;; `org-koma-letter-prefer-special-headings'.
;;
;; You need an appropriate association in `org-latex-classes' in order
;; to use the KOMA Scrlttr2 class.  By default, a sparse scrlttr2
;; class is provided: "default-koma-letter".  You can also add you own
;; letter class.  For instance:
;;
;;   (add-to-list 'org-latex-classes
;;                '("my-letter"
;;                  "\\documentclass\[%
;;   DIV=14,
;;   fontsize=12pt,
;;   parskip=half,
;;   subject=titled,
;;   backaddress=false,
;;   fromalign=left,
;;   fromemail=true,
;;   fromphone=true\]\{scrlttr2\}
;;   \[DEFAULT-PACKAGES]
;;   \[PACKAGES]
;;   \[EXTRA]"))
;;
;; Then, in your Org document, be sure to require the proper class
;; with:
;;
;;    #+LATEX_CLASS: my-letter
;;
;; Or by setting `org-koma-letter-default-class'.
;;
;; You may have to load (LaTeX) Babel as well, e.g., by adding
;; it to `org-latex-packages-alist',
;;
;;    (add-to-list 'org-latex-packages-alist '("AUTO" "babel" nil))

;;; Code:

(require 'ox-latex)

;; Install a default letter class.
(unless (assoc "default-koma-letter" org-latex-classes)
  (add-to-list 'org-latex-classes
	       '("default-koma-letter" "\\documentclass[11pt]{scrlttr2}")))


;;; User-Configurable Variables

(defgroup org-export-koma-letter nil
  "Options for exporting to KOMA scrlttr2 class in LaTeX export."
  :tag "Org Koma-Letter"
  :group 'org-export)

(defcustom org-koma-letter-class-option-file "NF"
  "Letter Class Option File.
This option can also be set with the LCO keyword."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-author 'user-full-name
  "Sender's name.

This variable defaults to calling the function `user-full-name'
which just returns the current function `user-full-name'.
Alternatively a string, nil or a function may be given.
Functions must return a string.

This option can also be set with the AUTHOR keyword."
  :group 'org-export-koma-letter
  :type '(radio (function-item user-full-name)
		(string)
		(function)
		(const :tag "Do not export author" nil)))

(defcustom org-koma-letter-email 'org-koma-letter-email
  "Sender's email address.

This variable defaults to the value `org-koma-letter-email' which
returns `user-mail-address'.  Alternatively a string, nil or
a function may be given.  Functions must return a string.

This option can also be set with the EMAIL keyword."
  :group 'org-export-koma-letter
  :type '(radio (function-item org-koma-letter-email)
		(string)
		(function)
		(const :tag "Do not export email" nil)))

(defcustom org-koma-letter-from-address ""
  "Sender's address, as a string.
This option can also be set with one or more FROM_ADDRESS
keywords."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-phone-number ""
  "Sender's phone number, as a string.
This option can also be set with the PHONE_NUMBER keyword."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-place ""
  "Place from which the letter is sent, as a string.
This option can also be set with the PLACE keyword."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-opening ""
  "Letter's opening, as a string.

This option can also be set with the OPENING keyword.  Moreover,
when:
  (1) this value is the empty string;
  (2) there's no OPENING keyword or it is empty;
  (3) `org-koma-letter-headline-is-opening-maybe' is non-nil;
  (4) the letter contains a headline without a special
      tag (e.g. \"to\" or \"ps\");
then the opening will be implicitly set as the headline title."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-closing ""
  "Letter's closing, as a string.
This option can also be set with the CLOSING keyword."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-signature ""
  "Signature, as a string.
This option can also be set with the SIGNATURE keyword."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-prefer-special-headings nil
  "Non-nil means prefer headlines over keywords for TO and FROM.
This option can also be set with the OPTIONS keyword, e.g.:
\"special-headings:t\"."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-subject-format t
  "Use the title as the subject of the letter.

When t, insert a subject using default options.  When nil, do not
insert a subject at all.  It can also be a list of symbols among
the following ones:

 `afteropening'  Subject after opening
 `beforeopening' Subject before opening
 `centered'      Subject centered
 `left'          Subject left-justified
 `right'         Subject right-justified
 `titled'        Add title/description to subject
 `underlined'    Set subject underlined
 `untitled'      Do not add title/description to subject

Please refer to the KOMA-script manual (Table 4.16. in the
English manual of 2012-07-22).

This option can also be set with the OPTIONS keyword, e.g.:
\"subject:(underlined centered)\"."
  :type
  '(choice
    (const :tag "No export" nil)
    (const :tag "Default options" t)
    (set :tag "Configure options"
	 (const :tag "Subject after opening" afteropening)
	 (const :tag "Subject before opening" beforeopening)
	 (const :tag "Subject centered" centered)
	 (const :tag "Subject left-justified" left)
	 (const :tag "Subject right-justified" right)
	 (const :tag "Add title or description to subject" underlined)
	 (const :tag "Set subject underlined" titled)
	 (const :tag "Do not add title or description to subject" untitled)))
  :group 'org-export-koma-letter)

(defcustom org-koma-letter-use-backaddress nil
  "Non-nil prints return address in line above to address.
This option can also be set with the OPTIONS keyword, e.g.:
\"backaddress:t\"."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-use-foldmarks t
  "Configure appearance of folding marks.

When t, activate default folding marks.  When nil, do not insert
folding marks at all.  It can also be a list of symbols among the
following ones:

  `B'  Activate upper horizontal mark on left paper edge
  `b'  Deactivate upper horizontal mark on left paper edge

  `H'  Activate all horizontal marks on left paper edge
  `h'  Deactivate all horizontal marks on left paper edge

  `L'  Activate left vertical mark on upper paper edge
  `l'  Deactivate left vertical mark on upper paper edge

  `M'  Activate middle horizontal mark on left paper edge
  `m'  Deactivate middle horizontal mark on left paper edge

  `P'  Activate punch or center mark on left paper edge
  `p'  Deactivate punch or center mark on left paper edge

  `T'  Activate lower horizontal mark on left paper edge
  `t'  Deactivate lower horizontal mark on left paper edge

  `V'  Activate all vertical marks on upper paper edge
  `v'  Deactivate all vertical marks on upper paper edge

This option can also be set with the OPTIONS keyword, e.g.:
\"foldmarks:(b l m t)\"."
  :group 'org-export-koma-letter
  :type '(choice
	  (const :tag "Activate default folding marks" t)
	  (const :tag "Deactivate folding marks" nil)
	  (set
	   :tag "Configure folding marks"
	   (const :tag "Activate upper horizontal mark on left paper edge" B)
	   (const :tag "Deactivate upper horizontal mark on left paper edge" b)
	   (const :tag "Activate all horizontal marks on left paper edge" H)
	   (const :tag "Deactivate all horizontal marks on left paper edge" h)
	   (const :tag "Activate left vertical mark on upper paper edge" L)
	   (const :tag "Deactivate left vertical mark on upper paper edge" l)
	   (const :tag "Activate middle horizontal mark on left paper edge" M)
	   (const :tag "Deactivate middle horizontal mark on left paper edge" m)
	   (const :tag "Activate punch or center mark on left paper edge" P)
	   (const :tag "Deactivate punch or center mark on left paper edge" p)
	   (const :tag "Activate lower horizontal mark on left paper edge" T)
	   (const :tag "Deactivate lower horizontal mark on left paper edge" t)
	   (const :tag "Activate all vertical marks on upper paper edge" V)
	   (const :tag "Deactivate all vertical marks on upper paper edge" v))))

(defcustom org-koma-letter-use-phone nil
  "Non-nil prints sender's phone number.
This option can also be set with the OPTIONS keyword, e.g.:
\"phone:t\"."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-use-email nil
  "Non-nil prints sender's email address.
This option can also be set with the OPTIONS keyword, e.g.:
\"email:t\"."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-use-place t
  "Non-nil prints the letter's place next to the date.
This option can also be set with the OPTIONS keyword, e.g.:
\"place:nil\"."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-use-title t
  "Non-nil means use a title in the letter if present.
This option can also be set with the OPTIONS keyword,
e.g. \"with-title:nil\".

See also `org-koma-letter-prefer-subject' for the handling of
title versus subject."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-default-class "default-koma-letter"
  "Default class for `org-koma-letter'.
The value must be a member of `org-latex-classes'."
  :group 'org-export-koma-letter
  :type 'string)

(defcustom org-koma-letter-headline-is-opening-maybe t
  "Non-nil means a headline may be used as an opening.
A headline is only used if #+OPENING is not set.  See also
`org-koma-letter-opening'."
  :group 'org-export-koma-letter
  :type 'boolean)

(defcustom org-koma-letter-prefer-subject nil
  "Non-nil means title should be interpret as subject if subject is missing.
This option can also be set with the OPTIONS keyword,
e.g. \"title-subject:t\".

This may be useful for older documents where the SUBJECT keyword
was not present."
    :group 'org-export-koma-letter
    :type 'boolean)

(defconst org-koma-letter-special-tags-in-letter '(to from)
  "Header tags related to the letter itself.")

(defconst org-koma-letter-special-tags-after-closing '(ps encl cc)
  "Header tags to be inserted after closing.")

(defconst org-koma-letter-special-tags-after-letter '(after_letter)
  "Header tags to be inserted after closing.")

(defvar org-koma-letter-special-contents nil
  "Holds special content temporarily.")



;;; Define Back-End

(org-export-define-derived-backend 'koma-letter 'latex
  :options-alist
  '((:latex-class "LATEX_CLASS" nil org-koma-letter-default-class t)
    (:lco "LCO" nil org-koma-letter-class-option-file)
    (:author "AUTHOR" nil (org-koma-letter--get-value org-koma-letter-author) t)
    (:from-address "FROM_ADDRESS" nil nil newline)
    (:phone-number "PHONE_NUMBER" nil org-koma-letter-phone-number)
    (:email "EMAIL" nil (org-koma-letter--get-value org-koma-letter-email) t)
    (:to-address "TO_ADDRESS" nil nil newline)
    (:place "PLACE" nil org-koma-letter-place)
    (:opening "OPENING" nil org-koma-letter-opening)
    (:closing "CLOSING" nil org-koma-letter-closing)
    (:signature "SIGNATURE" nil org-koma-letter-signature newline)
    (:subject "SUBJECT" nil nil space)
    (:special-headings nil "special-headings"
		       org-koma-letter-prefer-special-headings)
    (:special-tags nil nil (append
			    org-koma-letter-special-tags-in-letter
			    org-koma-letter-special-tags-after-closing
			    org-koma-letter-special-tags-after-letter))
    (:with-after-closing nil "after-closing-order"
			 org-koma-letter-special-tags-after-closing)
    (:with-after-letter nil "after-letter-order"
			org-koma-letter-special-tags-after-letter)
    (:with-backaddress nil "backaddress" org-koma-letter-use-backaddress)
    (:with-email nil "email" org-koma-letter-use-email)
    (:with-foldmarks nil "foldmarks" org-koma-letter-use-foldmarks)
    (:with-phone nil "phone" org-koma-letter-use-phone)
    (:with-place nil "place" org-koma-letter-use-place)
    (:with-subject nil "subject" org-koma-letter-subject-format)
    (:with-title nil "title" org-koma-letter-use-title)
    (:with-title-as-subject nil "title-subject" org-koma-letter-prefer-subject)
    ;; Special properties non-nil when a setting happened in buffer.
    ;; They are used to prioritize in-buffer settings over "lco"
    ;; files.  See `org-koma-letter-template'.
    (:inbuffer-author "AUTHOR" nil 'koma-letter:empty)
    (:inbuffer-email "EMAIL" nil 'koma-letter:empty)
    (:inbuffer-phone-number "PHONE_NUMBER" nil 'koma-letter:empty)
    (:inbuffer-place "PLACE" nil 'koma-letter:empty)
    (:inbuffer-signature "SIGNATURE" nil 'koma-letter:empty)
    (:inbuffer-with-backaddress nil "backaddress" 'koma-letter:empty)
    (:inbuffer-with-email nil "email" 'koma-letter:empty)
    (:inbuffer-with-foldmarks nil "foldmarks" 'koma-letter:empty)
    (:inbuffer-with-phone nil "phone" 'koma-letter:empty))
  :translate-alist '((export-block . org-koma-letter-export-block)
		     (export-snippet . org-koma-letter-export-snippet)
		     (headline . org-koma-letter-headline)
		     (keyword . org-koma-letter-keyword)
		     (template . org-koma-letter-template))
  :menu-entry
  '(?k "Export with KOMA Scrlttr2"
       ((?L "As LaTeX buffer" org-koma-letter-export-as-latex)
	(?l "As LaTeX file" org-koma-letter-export-to-latex)
	(?p "As PDF file" org-koma-letter-export-to-pdf)
	(?o "As PDF file and open"
	    (lambda (a s v b)
	      (if a (org-koma-letter-export-to-pdf t s v b)
		(org-open-file (org-koma-letter-export-to-pdf nil s v b))))))))



;;; Helper functions

(defun org-koma-letter-email ()
  "Return the current `user-mail-address'."
  user-mail-address)

;; The following is taken from/inspired by ox-grof.el
;; Thanks, Luis!

(defun org-koma-letter--get-tagged-contents (key)
  "Get contents from a headline tagged with KEY.
The contents is stored in `org-koma-letter-special-contents'."
  (cdr (assoc (org-koma-letter--get-value key)
	      org-koma-letter-special-contents)))

(defun org-koma-letter--get-value (value)
  "Turn value into a string whenever possible.
Determines if VALUE is nil, a string, a function or a symbol and
return a string or nil."
  (when value
    (cond ((stringp value) value)
	  ((functionp value) (funcall value))
	  ((symbolp value) (symbol-name value))
	  (t value))))

(defun org-koma-letter--special-contents-as-macro
  (keywords &optional keep-newlines no-tag)
  "Process KEYWORDS  members of `org-koma-letter-special-contents'.
KEYWORDS is a list of symbols.  Return them as a string to be
formatted.

The function is used for inserting content of special headings
such as PS.

If KEEP-NEWLINES is t newlines will not be removed.  If NO-TAG is
t the content in `org-koma-letter-special-contents' will not be
wrapped in a macro named whatever the members of KEYWORDS are
called."
  (mapconcat
   #'(lambda (keyword)
       (let* ((name (org-koma-letter--get-value keyword))
	      (value (org-koma-letter--get-tagged-contents name)))
	 (when value
	   (if no-tag (if keep-newlines value (org-trim value))
	     (format "\\%s{%s}\n"
		     name
		     (if keep-newlines value (org-trim value)))))))
   keywords
   ""))

(defun org-koma-letter--determine-to-and-from (info key)
  "Given INFO determine KEY for the letter.
KEY should be `to' or `from'.

`ox-koma-letter' allows two ways to specify TO and FROM.  If both
are present return the preferred one as determined by
`org-koma-letter-prefer-special-headings'."
  (let ((option (plist-get info (if (eq key 'to) :to-address :from-address)))
	(headline (org-koma-letter--get-tagged-contents key)))
    (replace-regexp-in-string
     "\n" "\\\\\\\\\n"
     (org-trim
      (or (if (plist-get info :special-headings) (or headline option)
	    (or option headline))
	  ;; Fallback values.
	  (if (eq key 'to) "\\mbox{}" org-koma-letter-from-address))))))



;;; Transcode Functions

;;;; Export Block

(defun org-koma-letter-export-block (export-block contents info)
  "Transcode an EXPORT-BLOCK element into KOMA Scrlttr2 code.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (when (member (org-element-property :type export-block) '("KOMA-LETTER" "LATEX"))
    (org-remove-indentation (org-element-property :value export-block))))

;;;; Export Snippet

(defun org-koma-letter-export-snippet (export-snippet contents info)
  "Transcode an EXPORT-SNIPPET object into KOMA Scrlttr2 code.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (when (memq (org-export-snippet-backend export-snippet) '(latex koma-letter))
    (org-element-property :value export-snippet)))

;;;; Keyword

(defun org-koma-letter-keyword (keyword contents info)
  "Transcode a KEYWORD element into KOMA Scrlttr2 code.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (let ((key (org-element-property :key keyword))
	(value (org-element-property :value keyword)))
    ;; Handle specifically KOMA-LETTER keywords.  Otherwise, fallback
    ;; to `latex' back-end.
    (if (equal key "KOMA-LETTER") value
      (org-export-with-backend 'latex keyword contents info))))

;; Headline

(defun org-koma-letter-headline (headline contents info)
  "Transcode a HEADLINE element from Org to LaTeX.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information.

Note that if a headline is tagged with a tag from
`org-koma-letter-special-tags' it will not be exported, but
stored in `org-koma-letter-special-contents' and included at the
appropriate place."
  (unless (let ((tag (car (org-export-get-tags headline info))))
	    (and tag
		 (member-ignore-case
		  tag (mapcar #'symbol-name (plist-get info :special-tags)))
		 ;; Store association for later use and bail out.
		 (push (cons tag contents) org-koma-letter-special-contents)))
    ;; Opening is not defined yet: use headline's title.
    (when (and org-koma-letter-headline-is-opening-maybe
	       (not (org-string-nw-p (plist-get info :opening))))
      (plist-put info :opening
		 (org-export-data (org-element-property :title headline) info)))
    ;; In any case, insert contents in letter's body.
    contents))

;;;; Template

(defun org-koma-letter-template (contents info)
  "Return complete document string after KOMA Scrlttr2 conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; Time-stamp.
   (and (plist-get info :time-stamp-file)
        (format-time-string "%% Created %Y-%m-%d %a %H:%M\n"))
   ;; Document class and packages.
   (let* ((class (plist-get info :latex-class))
	  (class-options (plist-get info :latex-class-options))
	  (header (nth 1 (assoc class org-latex-classes)))
	  (document-class-string
	   (and (stringp header)
		(if (not class-options) header
		  (replace-regexp-in-string
		   "^[ \t]*\\\\documentclass\\(\\(\\[[^]]*\\]\\)?\\)"
		   class-options header t nil 1)))))
     (if (not document-class-string)
	 (user-error "Unknown LaTeX class `%s'" class)
       (org-latex-guess-babel-language
	(org-latex-guess-inputenc
	 (org-element-normalize-string
	  (org-splice-latex-header
	   document-class-string
	   org-latex-default-packages-alist ; Defined in org.el.
	   org-latex-packages-alist nil     ; Defined in org.el.
	   (concat (org-element-normalize-string (plist-get info :latex-header))
		   (plist-get info :latex-header-extra)))))
	info)))
   ;; Settings.  They can come from three locations, in increasing
   ;; order of precedence: global variables, LCO files and in-buffer
   ;; settings.  Thus, we first insert settings coming from global
   ;; variables, then we insert LCO files, and, eventually, we insert
   ;; settings coming from buffer keywords.
   (org-koma-letter--build-settings 'global info)
   (mapconcat #'(lambda (file) (format "\\LoadLetterOption{%s}\n" file))
	      (org-split-string (or (plist-get info :lco) "") " ")
	      "")
   (org-koma-letter--build-settings 'buffer info)
   ;; From address.
   (let ((from-address (org-koma-letter--determine-to-and-from info 'from)))
     (and from-address (format "\\setkomavar{fromaddress}{%s}\n" from-address)))
   ;; Date.
   (format "\\date{%s}\n" (org-export-data (org-export-get-date info) info))
   ;; Document start
   "\\begin{document}\n\n"
   ;; Subject and title
   (let ((with-subject (plist-get info :with-subject)))
     (when with-subject
       (concat
	(unless (eq with-subject t)
	  (format "\\KOMAoption{subject}{%s}\n"
		  (if (symbolp with-subject) with-subject
		    (mapconcat #'symbol-name with-subject ","))))
	(let* ((title-as-subject (plist-get info :with-title-as-subject))
	       (subject* (org-string-nw-p
			  (org-export-data (plist-get info :subject) info)))
	       (title* (and (plist-get info :with-title)
			    (org-string-nw-p
			     (org-export-data (plist-get info :title) info))))
	       (subject (if title-as-subject (or subject* title*) subject*))
	       (title (if title-as-subject (and subject* title*) title*)))
	  (concat
	   (and subject (format "\\setkomavar{subject}{%s}\n" subject))
	   (and title (format "\\setkomavar{title}{%s}\n" title))
	   (when (or (org-string-nw-p title) (org-string-nw-p subject)) "\n"))))))
   ;; Letter start.
   (format "\\begin{letter}{%%\n%s}\n\n"
	   (org-koma-letter--determine-to-and-from info 'to))
   ;; Opening.
   (format "\\opening{%s}\n\n" (plist-get info :opening))
   ;; Letter body.
   contents
   ;; Closing.
   (format "\n\\closing{%s}\n" (plist-get info :closing))
   (org-koma-letter--special-contents-as-macro
    (plist-get info :with-after-closing))
   ;; Letter end.
   "\n\\end{letter}\n"
   (org-koma-letter--special-contents-as-macro
    (plist-get info :with-after-letter) t t)
   ;; Document end.
   "\n\\end{document}"))

(defun org-koma-letter--build-settings (scope info)
  "Build settings string according to type.
SCOPE is either `global' or `buffer'.  INFO is a plist used as
a communication channel."
  (let ((check-scope
         (function
          ;; Non-nil value when SETTING was defined in SCOPE.
          (lambda (setting)
            (let ((property (intern (format ":inbuffer-%s" setting))))
              (if (eq scope 'global)
		  (eq (plist-get info property) 'koma-letter:empty)
                (not (eq (plist-get info property) 'koma-letter:empty))))))))
    (concat
     ;; Name.
     (let ((author (plist-get info :author)))
       (and author
            (funcall check-scope 'author)
            (format "\\setkomavar{fromname}{%s}\n"
                    (org-export-data author info))))
     ;; Email.
     (let ((email (plist-get info :email)))
       (and email
            (funcall check-scope 'email)
            (format "\\setkomavar{fromemail}{%s}\n" email)))
     (and (funcall check-scope 'with-email)
          (format "\\KOMAoption{fromemail}{%s}\n"
                  (if (plist-get info :with-email) "true" "false")))
     ;; Phone number.
     (let ((phone-number (plist-get info :phone-number)))
       (and (org-string-nw-p phone-number)
            (funcall check-scope 'phone-number)
            (format "\\setkomavar{fromphone}{%s}\n" phone-number)))
     (and (funcall check-scope 'with-phone)
          (format "\\KOMAoption{fromphone}{%s}\n"
                  (if (plist-get info :with-phone) "true" "false")))
     ;; Signature.
     (let ((signature (plist-get info :signature)))
       (and (org-string-nw-p signature)
            (funcall check-scope 'signature)
            (format "\\setkomavar{signature}{%s}\n" signature)))
     ;; Back address.
     (and (funcall check-scope 'with-backaddress)
          (format "\\KOMAoption{backaddress}{%s}\n"
                  (if (plist-get info :with-backaddress) "true" "false")))
     ;; Place.
     (and (funcall check-scope 'place)
          (format "\\setkomavar{place}{%s}\n"
                  (if (plist-get info :with-place) (plist-get info :place) "")))
     ;; Folding marks.
     (and (funcall check-scope 'with-foldmarks)
          (let ((foldmarks (plist-get info :with-foldmarks)))
	    (cond ((consp foldmarks)
		   (format "\\KOMAoptions{foldmarks=true,foldmarks=%s}\n"
			   (mapconcat #'symbol-name foldmarks "")))
		  (foldmarks "\\KOMAoptions{foldmarks=true}\n")
		  (t "\\KOMAoptions{foldmarks=false}\n")))))))



;;; Commands

;;;###autoload
(defun org-koma-letter-export-as-latex
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer as a KOMA Scrlttr2 letter.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\begin{letter}\" and \"\\end{letter}\".

EXT-PLIST, when provided, is a proeprty list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org KOMA-LETTER Export*\".  It
will be displayed if `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (let (org-koma-letter-special-contents)
    (org-export-to-buffer 'koma-letter "*Org KOMA-LETTER Export*"
      async subtreep visible-only body-only ext-plist
      (lambda () (LaTeX-mode)))))

;;;###autoload
(defun org-koma-letter-export-to-latex
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer as a KOMA Scrlttr2 letter (tex).

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\begin{letter}\" and \"\\end{letter}\".

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

When optional argument PUB-DIR is set, use it as the publishing
directory.

Return output file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".tex" subtreep))
	(org-koma-letter-special-contents))
    (org-export-to-file 'koma-letter outfile
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun org-koma-letter-export-to-pdf
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer as a KOMA Scrlttr2 letter (pdf).

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\begin{letter}\" and \"\\end{letter}\".

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return PDF file's name."
  (interactive)
  (let ((file (org-export-output-file-name ".tex" subtreep))
	(org-koma-letter-special-contents))
    (org-export-to-file 'koma-letter file
      async subtreep visible-only body-only ext-plist
      (lambda (file) (org-latex-compile file)))))


(provide 'ox-koma-letter)
;;; ox-koma-letter.el ends here

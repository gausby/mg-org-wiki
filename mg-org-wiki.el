;;; mg-org-wiki.el --- A wiki system heavily piggybacking on org-mode

;; Author: Martin Gausby <martin@gausby.dk>
;; Keywords: org wiki
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/gausby/mg-org-wiki

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; MG Org Wiki
;; ===========

;; mg/org-wiki is a set of helpers and configurations of org-mode that
;; implements a wiki-like system that allow the user to easily create
;; new pages, link pages, and search already existing for pages.

;; Features
;; --------

;; - Page creation featuring an auto-insert skeleton
;; - Find existing pages by topic, or create new ones if not found
;; - Keyword search using counsel-ag

;; Requirements
;; ------------

;; - Emacs
;; - org-mode
;; - Ivy/Counsel
;; - ag (silver-searcher) should be present on the underlying system

;;; Code:

(require 'org)
(require 'autoinsert)

(defcustom mg/org-wiki-location "~/Notes/wiki/"
  "The folder where the org files for the wiki are located"
  :type 'dictionary
  :group 'mg/org-wiki)

;; creating new files
(defvar mg/org-wiki-metadata-skeleton
  '(nil
    "#+TITLE: " (file-name-base (buffer-name)) "\n"
    "#+KEYWORDS: " (skeleton-read "keywords: " "") "\n\n"
    "* " _))

(define-auto-insert
  (wildcard-to-regexp (expand-file-name "*.org" mg/org-wiki-location))
  mg/org-wiki-metadata-skeleton)


;; Opening files
(defun mg/org-wiki-visit-entry (topic)
  "Open a file on the `topic' in the directory defined in
`mg/org-wiki-location'. If no file is found for the given topic
it will get created"
  (unless (string-blank-p topic)
    (let* ((default-directory mg/org-wiki-location)
           (trimmed-topic (string-trim topic))
           (entry
            (if (string-equal "org" (file-name-extension trimmed-topic))
                trimmed-topic (concat trimmed-topic ".org"))))
      (find-file (expand-file-name entry)))))


(defun mg/org-wiki-find-entry ()
  "Find or create a page with auto-completion of the already
existing files"
  (interactive)
  (let ((default-directory mg/org-wiki-location))
  (mg/org-wiki-visit-entry
   (completing-read
    "Open wiki page: "
    (mapcar 'file-name-base
            (file-expand-wildcards (expand-file-name "*.org")))))))


(defun mg/org-wiki-find-entry-on-current-major-mode ()
  "Open the wiki entry on the major mode of the file currently
being visited. This allows the user to take notes on the usage or
a major mode or programming language"
  (interactive)
  (let ((current-mode (symbol-name major-mode)))
    (mg/org-wiki-visit-entry (concat current-mode " (major mode)"))))


(defun mg/org-wiki-is-wiki-entry (file)
  (let ((wiki-dir (file-truename mg/org-wiki-location))
        (file-dir (file-name-directory file)))
    (and (string-equal (file-name-extension file) "org")
         (string-equal wiki-dir file-dir))))


;; Closing files
(defun mg/org-wiki-kill-all-non-modified-entries ()
  "Kill all open wiki buffers; ask if modified"
  (interactive)
  (let ((buffers (buffer-list (selected-frame))))
    (dolist (buffer buffers)
      (with-current-buffer buffer
        (let ((current-buffer-name (buffer-file-name buffer)))
          (unless (null current-buffer-name)
            (when (mg/org-wiki-is-wiki-entry current-buffer-name)
              (kill-buffer buffer))))))))


;; Searching
(defun mg/org-wiki-links-here (&optional file)
  "Look for incoming references to the `file', if no file is
specified the currently opened file will be used as the query"
  (interactive)
  (let ((topic (if (eq file nil) buffer-file-name file)))
    (if (mg/org-wiki-is-wiki-entry topic)
        (let ((query (format "\\[\\[wiki:%s\\]?.*\\]"
                             (file-name-nondirectory topic))))
          (counsel-ag query mg/org-wiki-location))
      nil)))


(defun mg/org-wiki-find-keyword ()
  "Look for files that has the given keyword; It will use a
simple silver searcher query pre-filled with `#+KEYWORDS: ', from
there the query can be narrowed down; use pipe (`|') if the query
should contain more than one keyword"
  (interactive)
  (counsel-ag "^#\\+KEYWORDS: " mg/org-wiki-location))


(with-eval-after-load 'org
  (add-to-list 'org-link-parameters
             '("wiki" :follow mg/org-wiki-visit-entry)))


(provide 'mg/org-wiki)
;;; mg-org-wiki.el ends here

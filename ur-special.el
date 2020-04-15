;; This package changes the behavior of Org Mode so that
;; you can never edit the text inside a special block
;; (i.e. a Babel source block) without being in the proper
;; mode via (org-edit-special). To leave the special editing
;; buffer, simply move point beyond the first or last line.

;; To use ur-special, add the repository to your load path and
;; add the following to your init file:
;;   (require 'ur-special)
;;   (ur-special-enable)

(require 'org)

;; HELPERS
(defun ur-special--point-is-inside-special-block ()
	"Check if the point is inside a special block"
	(let ((last-block-start
				 (save-excursion
					 (condition-case nil
							 (search-backward "#+begin_")
						 (error (goto-char (point-max))))
					 (line-number-at-pos)))
				 (last-block-end
					(save-excursion
						(condition-case nil
								(search-backward "#+end_")
							(error (goto-char (point-min))))
						(line-number-at-pos))))
			(< last-block-end last-block-start (line-number-at-pos))))

(defun ur-special--check-and-enter-special-block ()
	"If point is in a special block, open a special buffer"
	(when (and (eq major-mode 'org-mode) (ur-special--point-is-inside-special-block))
		(org-edit-special)
		(delete-other-windows)))

(defun ur-special--check-exit-special-buffer-up (&optional arg try-vscroll)
	"If point is at the first line of the special buffer, exit it"
	(when (and (bound-and-true-p org-src-mode)
						 (= (line-number-at-pos) 1))
		(org-edit-src-exit)))

(defun ur-special--check-exit-special-buffer-down (&optional arg try-vscroll)
	"If point is at the last line of the special buffer, exit it."
	(when (and (bound-and-true-p org-src-mode)
						 (>= (line-number-at-pos) (save-excursion (end-of-buffer) (line-number-at-pos))))
		;; This gets a bit hacky, because unless we disable the hooks before doing this, it'll
		;; put us right back where we started.
		(ur-special--disable-post-command-hook)
		(org-edit-src-exit)
		(search-forward "#+end_src")
		(next-line)
		(ur-special--enable-post-command-hook)))

(defun ur-special--enable-post-command-hook ()
	;; For internal use only. 
	(add-hook 'post-command-hook #'ur-special--check-and-enter-special-block nil t))

(defun ur-special--disable-post-command-hook ()
	;; For internal use only.
	(remove-hook 'post-command-hook #'ur-special--check-and-enter-special-block t))

(defun ur-special-enable ()
	"Enable ur-special behavior."
	(interactive)
	(advice-add #'previous-line :before #'ur-special--check-exit-special-buffer-up)
	(advice-add #'next-line :before #'ur-special--check-exit-special-buffer-down)
	(add-hook 'org-mode-hook #'ur-special--enable-post-command-hook))

(defun ur-special-disable ()
	"Disable ur-special behavior."
	(interactive)
	(ignore-errors
		(ur-special--disable-post-command-hook)
		(advice-remove #'previous-line #'ur-special--check-exit-special-buffer-up)
		(advice-remove #'previous-line #'ur-special--check-exit-special-buffer-down)
		(add-hook #'org-mode-hook #'ur-special--enable-post-command-hook)))

(provide 'ur-special)

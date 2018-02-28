(global-set-key "\C-ccms" 'code-monkey-refactory-suggest-refactorings)
(global-set-key "\C-ccmf" 'code-monkey-format-buffer-with-perltidy)

(defun code-monkey-refactory-suggest-refactorings ()
 "Suggest items to be refactored"
 (interactive)
 (message
  (shell-command-to-string
   (concat "/var/lib/myfrdcsa/codebases/internal/code-monkey/scripts/suggest-refactorings.pl -f " 
    (shell-quote-argument
     (buffer-name
      (current-buffer)))))))

(defun code-monkey-format-this-attribute-list ()
 "Takes a list in front of it, and spits out a bunch of formatted
attributes for inits"
 (interactive)
 (setq last-kbd-macro
  "$self->\C-i\C-@\C-[\C-f\C-[w(\C-y\C-[b$args{\C-[f});\C-i\C-m"))

(defun code-monkey-format-buffer-with-perltidy
 ""
 (interactive)
 ;; add a check for a perl source extension
 (let* ((filename "/tmp/code-monkey-perl-export.pl")
	(perltidyfilename (concat filename ".tdy")))
  (write-file filename)
  (shell-command (concat "perltidy " filename))
  (if (file-exists-p perltidyfilename)
   (progn
    (mark-whole-buffer)
    (kill-region)
    (insert (shell-command-to-string (concat "cat " perltidyfilename)))
   ))))

(provide 'code-monkey)
;;; code-monkey.el ends here

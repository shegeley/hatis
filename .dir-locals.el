((scheme-mode
  .
   ((geiser-mode-auto-p . nil)
    (indent-tabs-mode . nil)
    (eval . (setq lisp-indent-offset 1))
    (eval . (eval-after-load "arei"
             ;; don't kill arei buffer when the process is dead; when dealing with SIGSEGV there might be some useful prints
             '(defun arei-client--sentinel (process message)
               "Called when connection is changed; in out case dropped."
               (message "nREPL connection closed: %s" message)
               ;; (kill-buffer (process-buffer process))
               ))))))

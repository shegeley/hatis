#!/usr/bin/env bash

# # geiser
# guix shell guile -f guix.scm \
#      --rebuild-cache --development \
#      -- guile \
#      --listen=1338

# ares + arei
guix shell \
     --development \
     --rebuild-cache \
     --no-substitutes \
     guile-next \
     guile-ares-rs \
     -f guix.scm \
     -- guile \
     -e '((@ (nrepl server) run-nrepl-server) #:port 7888)'

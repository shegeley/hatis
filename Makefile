# base stubs
guix-time-machine = guix time-machine -C ./channels-lock.scm

guile-shell-default-args = \
	guile-next \
	guile-ares-rs \
	-L channel \
	--no-substitutes #--rebuild-cache

commonlisp-shell-default-args = \
	sbcl \
	sbcl-slynk \
	-L channel \
	-D -f guix.scm \
	--rebuild-cache

nrepl-file = "ares.scm"

slynk-file = "repl.lisp"

guile = ${guile-shell-default-args} -- guile -L ./src

commonlisp = ${commonlisp-shell-default-args} -- sbcl --load ${slynk-file}

slynk:
	guix shell ${commonlisp}

lsp:
	guix shell \
	-L channel \
	sbcl sbcl-alive-lsp \
	-D -f guix.scm \
	--rebuild-cache \
	-- sbcl \
	--eval "(require :asdf)" \
	--eval "(asdf:load-system :alive-lsp)" \
	--eval "(alive/server:start)"

nrepl:
	guix shell ${guile} -l ${nrepl-file}

build:
	guix build -f guix.scm -L channel

sway-nrepl-cmd = "exec foot make nrepl; exec foot"
sway-tm/nrepl-cmd = "exec foot make tm/nrepl; exec foot"

sway+nrepl: # have to create tmpfile for `sway -c`
	$(eval TMP := $(shell mktemp))
	@echo ${sway-nrepl-cmd} >> $(TMP)
	sway -c $(TMP)
	rm -rf $(TMP)

sway+tm/nrepl:
	$(eval TMP := $(shell mktemp))
	@echo ${sway-tm/nrepl-cmd} >> $(TMP)
	sway -c $(TMP)
	rm -rf $(TMP)

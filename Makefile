guix-time-machine = guix time-machine -C ./channels-lock.scm
shell-default-args = --development --rebuild-cache # cache might cause errors
guile = -- shell guile-next guile-ares-rs -f guix.scm  ${shell-default-args} -- guile
nrepl-exp = "((@ (nrepl server) run-nrepl-server) \#:port 7888)" # hashtag has to be escaped even inside string or it will count as comment

nrepl:
	${guix-time-machine} ${guile} -e ${nrepl-exp}

repl:
	${guix-time-machine} ${guile}

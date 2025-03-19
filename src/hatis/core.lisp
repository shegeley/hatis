(defpackage :xyz.hatis.core
 (:use
  :wayflan-client

  :xyz.hatis.protocols.data-control
  :xyz.hatis.protocols.input-method
  :xyz.hatis.protocols.foreign-toplevel-management

  :xyz.hatis.utils
  :xyz.hatis.classes
  :xyz.hatis.wayland.handlers

  :trivia

  :chanl
  :arrows
  :cl)
 (:import-from :wayflan-client :%proxy-table)
 (:import-from :xyz.hatis.classes :Hatis)
 (:import-from :xyz.hatis.classes :%display)
 (:import-from :xyz.hatis.classes :%channel)
 (:local-nicknames
  (:a :alexandria)))

(in-package :xyz.hatis.core)

(defparameter app nil)

(defmethod process-interface
 (H interface)
 "This method is called BEFORE all the interfaces are 'collected' into %proxy-table. So you can't rely on it's being filled on this method's first call"
 (format t "processing interface: ~a ~%" interface)
 (install-event-handlers! H interface))

(defun hatis-loop
  (hatis)
  (loop
   (let ((msg (recv (%channel hatis))))
    (format t "incoming message: ~a ~%" msg)
    (match msg
     ((list 'wayland-interface interface)
      (process-interface hatis interface))))))

(defun start! ()
 (print "Starting hatis…") (terpri)

 (with-open-display (display*)

  (let ((hatis (make-instance 'Hatis
                :display display*
                :channel (make-instance 'channel))))

   (setq app hatis)

   (with-slots
    ((display xyz.hatis.classes::display))
    hatis

    (pexec () (hatis-loop hatis))

    (process-interface hatis (wl-display.get-registry display))

    (wl-display-roundtrip display)
    (wl-display-roundtrip display)

    (process-interface hatis (get-input-method hatis))
    (process-interface hatis (get-data-control-device hatis))

    (loop
     (if (not (eql 'wl-destroyed-proxy (type-of display)))
      (wl-display-dispatch-event display)
      (return t)))))))

(defun stop! ()
 (handler-case
  (progn
   (print "Stopping hatis…") (terpri)
   (wl-display.sync (%display app))
   (wl-display-disconnect (%display app)))
  (error (c)
   (print "Coudn't stop hatis…") (terpri)
   (format *error-output* "Caught error: ~a ~%" c)
   nil)))

;; (stop!)
(start!)

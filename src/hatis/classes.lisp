(defpackage :xyz.hatis.classes
 (:use :wayflan-client :cl)
 (:export :Hatis :%display :%channel))

(in-package :xyz.hatis.classes)

(defclass Hatis ()
 ((display :type wl-display :initarg :display :accessor %display)
  (channel :type channel :initarg :channel :accessor %channel)))

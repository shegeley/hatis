(define-module (mmap)
  #:use-module (system foreign-library)
  #:use-module ((system foreign) #:prefix ffi:)

  #:export (PROT_READ PROT_WRITE
            MAP_SHARED MAP_PRIVATE
            memfd-create mmap mumnap))

;; Everything is stolen from ~guile-wayland/examples/wl-client-3.scm.in~
;; move to separate package?

(define PROT_READ 1)

(define PROT_WRITE 2)

(define MAP_SHARED 1)

(define MAP_PRIVATE 2)

(define memfd-create
  (let ((% (foreign-library-function
            #f  "memfd_create"
            #:return-type ffi:int
            #:arg-types `(* ,ffi:unsigned-int))))
    (lambda (name flags)
      (% (ffi:string->pointer name) flags))))

(define mmap
  (let ((% (foreign-library-function
            #f  "mmap"
            #:return-type '*
            #:arg-types `(* ,ffi:size_t ,ffi:int ,ffi:int ,ffi:int ,ffi:long))))
    (lambda (address length prot flags fd offset)
      (ffi:pointer->bytevector
       (% (or address ffi:%null-pointer) length prot flags fd offset)
       length))))

(define munmap
  (let ((% (foreign-library-function
            #f  "munmap"
            #:return-type ffi:int
            #:arg-types `(* ,ffi:size_t))))
    (lambda* (address)
      (%  (ffi:bytevector->pointer address)
          (bytevector-length address)))))

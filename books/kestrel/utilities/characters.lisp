; Character Utilities
;
; Copyright (C) 2018 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "std/util/deflist" :dir :system)
(include-book "std/util/defrule" :dir :system)
(include-book "std/typed-lists/unsigned-byte-listp" :dir :system)
(include-book "std/strings/hex" :dir :system)

(local (include-book "std/lists/top" :dir :system))
(local (include-book "std/typed-lists/character-listp" :dir :system))
(local (include-book "typed-list-theorems"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc character-utilities
  :parents (kestrel-utilities)
  :short "Utilities for @(see characters).")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define alpha/digit/dash-char-p ((char characterp))
  :returns (yes/no booleanp)
  :parents (character-utilities)
  :short "Check if a character is a letter, a (decimal) digit, or a dash."
  (or (and (standard-char-p char)
           (alpha-char-p char))
      (if (digit-char-p char) t nil)
      (eql char #\-)))

(std::deflist alpha/digit/dash-char-listp (x)
  (alpha/digit/dash-char-p x)
  :guard (character-listp x)
  :parents (character-utilities)
  :short "Check if a true list of characters includes only
          letters, (decimal) digits, and dashes."
  :true-listp t
  :elementp-of-nil nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define alpha/uscore/dollar-char-p ((char characterp))
  :returns (yes/no booleanp)
  :parents (character-utilities)
  :short "Check if a character is a letter, an underscore, or a dollar sign."
  (or (and (standard-char-p char)
           (alpha-char-p char))
      (eql char #\_)
      (eql char #\$)))

(std::deflist alpha/uscore/dollar-char-listp (x)
  (alpha/uscore/dollar-char-p x)
  :guard (character-listp x)
  :parents (character-utilities)
  :short "Check if a list of characters includes only
          letters, underscores, and dollar signs."
  :true-listp t
  :elementp-of-nil nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define alpha/digit/uscore/dollar-char-p ((char characterp))
  :returns (yes/no booleanp)
  :parents (character-utilities)
  :short "Check if a character is
          a letter, a (decimal) digit, an underscore, or a dollar sign."
  (or (and (standard-char-p char)
           (alpha-char-p char))
      (if (digit-char-p char) t nil)
      (eql char #\_)
      (eql char #\$)))

(std::deflist alpha/digit/uscore/dollar-char-listp (x)
  (alpha/digit/uscore/dollar-char-p x)
  :guard (character-listp x)
  :parents (character-utilities)
  :short "Check if a list of characters includes only
          letters, (decimal) digits, underscores, and dollar signs."
  :true-listp t
  :elementp-of-nil nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nondigit-char-p ((char characterp))
  :returns (yes/no booleanp)
  :parents (character-utilities)
  :short "Check if a character is not a (decimal) digit."
  (not (digit-char-p char)))

(std::deflist nondigit-char-listp (x)
  (nondigit-char-p x)
  :guard (character-listp x)
  :parents (character-utilities)
  :short "Check if a true list of characters includes no (decimal) digits."
  :true-listp t
  :elementp-of-nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define printable-char-p ((char characterp))
  :returns (yes/no booleanp)
  :parents (character-utilities)
  :short "Check if a character is a printable ASCII character,
          i.e. it is a space or a visible character."
  (b* ((code (char-code char)))
    (and (<= #x20 code)
         (<= code #x7e))))

(std::deflist printable-char-listp (x)
  (printable-char-p x)
  :guard (character-listp x)
  :parents (character-utilities)
  :short "Check if a list of characters includes only
          printable ASCII characters, i.e. spaces and visible characters."
  :true-listp t
  :elementp-of-nil nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define nats=>chars ((nats (unsigned-byte-listp 8 nats)))
  :returns (chars character-listp)
  :parents (character-utilities)
  :short "Convert a true list of natural numbers below 256
          to the corresponding true list of characters."
  :long
  "<p>
   This operation has
   a natural-recursive definition for logic reasoning
   and a tail-recursive executional for execution.
   </p>"
  (mbe :logic (cond ((endp nats) nil)
                    (t (cons (code-char (car nats))
                             (nats=>chars (cdr nats)))))
       :exec (nats=>chars-exec nats nil))
  :verify-guards nil ; done below

  :prepwork
  ((define nats=>chars-exec ((nats (unsigned-byte-listp 8 nats))
                             (rev-chars character-listp))
     (cond ((endp nats) (rev rev-chars))
           (t (nats=>chars-exec (cdr nats)
                                (cons (code-char (car nats))
                                      rev-chars))))
     :enabled t))

  ///

  (defrulel verify-guards-lemma-1
    (equal (nats=>chars-exec nats rev-chars)
           (revappend rev-chars (nats=>chars nats))))

  (defrulel verify-guards-lemma-2
    (equal (nats=>chars-exec nats nil)
           (nats=>chars nats)))

  (verify-guards nats=>chars)

  (defrule len-of-nats=>chars
    (equal (len (nats=>chars nats))
           (len nats)))

  (defrule nats=>chars-of-cons
    (equal (nats=>chars (cons nat nats))
           (cons (code-char nat)
                 (nats=>chars nats))))

  (defrule nats=>chars-of-append
    (equal (nats=>chars (append nats1 nats2))
           (append (nats=>chars nats1)
                   (nats=>chars nats2)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define chars=>nats ((chars character-listp))
  :returns (nats (unsigned-byte-listp 8 nats))
  :parents (character-utilities)
  :short "Convert a true list of characters
          to the corresponding true list of natural numbers below 256."
  :long
  "<p>
   This operation has
   a natural-recursive definition for logic reasoning
   and a tail-recursive executional for execution.
   </p>"
  (mbe :logic (cond ((endp chars) nil)
                    (t (cons (char-code (car chars))
                             (chars=>nats (cdr chars)))))
       :exec (chars=>nats-exec chars nil))
  :verify-guards nil ; done below

  :prepwork
  ((define chars=>nats-exec ((chars character-listp)
                             (rev-nats (unsigned-byte-listp 8 rev-nats)))
     (cond ((endp chars) (rev rev-nats))
           (t (chars=>nats-exec (cdr chars)
                                (cons (char-code (car chars))
                                      rev-nats))))
     :enabled t))

  ///

  (more-returns
   (nats nat-listp
         :name nat-listp-of-chars=>nats))

  (defrulel verify-guards-lemma-1
    (equal (chars=>nats-exec chars rev-nats)
           (revappend rev-nats (chars=>nats chars))))

  (defrulel verify-guards-lemma-2
    (equal (chars=>nats-exec chars nil)
           (chars=>nats chars)))

  (verify-guards chars=>nats)

  (defrule len-of-chars=>nats
    (equal (len (chars=>nats chars))
           (len chars)))

  (defrule chars=>nats-of-cons
    (equal (chars=>nats (cons char chars))
           (cons (char-code char)
                 (chars=>nats chars))))

  (defrule chars=>nats-of-append
    (equal (chars=>nats (append chars1 chars2))
           (append (chars=>nats chars1)
                   (chars=>nats chars2)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define ubyte8s=>hexchars ((bytes (unsigned-byte-listp 8 bytes)))
  :returns (chars character-listp)
  :parents (character-utilities)
  :short "Convert a list of natural numbers below 256
          to a sequence of hexadecimal digit characters."
  :long
  "<p>
   Each input natural number is converted to two hexadecimal digits,
   with a leading 0 digit if needed.
   The hexadecimal digits above 9 are upper case letters.
   The result is the concatenation of all these digits.
   </p>"
  (mbe :logic (cond ((endp bytes) nil)
                    (t (b* ((digits (str::natchars16 (car bytes)))
                            (digits (if (= (len digits) 2)
                                        digits
                                      (cons #\0 digits))))
                         (append digits
                                 (ubyte8s=>hexchars (cdr bytes))))))
       :exec (ubyte8s=>hexchars-aux bytes nil))
  :verify-guards nil ; done below

  :prepwork
  ((define ubyte8s=>hexchars-aux ((bytes (unsigned-byte-listp 8 bytes))
                                  (rev-chars character-listp))
     (cond ((endp bytes) (rev rev-chars))
           (t (b* ((digits (str::natchars16 (car bytes)))
                   (digits (if (= (len digits) 2)
                               digits
                             (cons #\0 digits))))
                (ubyte8s=>hexchars-aux (cdr bytes)
                                       (append (rev digits) rev-chars)))))
     :enabled t))

  ///

  (defrulel verify-guards-lemma
    (equal (ubyte8s=>hexchars-aux bytes rev-chars)
           (revappend rev-chars (ubyte8s=>hexchars bytes))))

  (verify-guards ubyte8s=>hexchars))

; CUTIL - Centaur Basic Utilities
; Copyright (C) 2008-2011 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.
;
; Original author: Jared Davis <jared@centtech.com>

(in-package "STD")
(include-book "defalist")

;; Basic tests to make sure defalist seems to be working.

(local (in-theory nil))

(local (in-theory (enable booleanp-compound-recognizer
                          (:executable-counterpart stringp)
                          (:executable-counterpart integerp)
                          (:executable-counterpart integer-listp)
                          (:type-prescription integer-listp))))


;; basic keyp-of-nil/valp-of-nil polarity testing...

(local (encapsulate ()
         (local (defalist string-int-alistp (x)
                  :key (stringp x)
                  :val (integerp x)))))

(local (encapsulate ()
         (local (defalist string-int-alist-2p (x)
                  :key (stringp x)
                  :val (integerp x)
                  :keyp-of-nil nil))))

(local (encapsulate ()
         (local (defalist string-int-alist-3p (x)
                  :key (stringp x)
                  :val (integerp x)
                  :valp-of-nil nil))))

(local (encapsulate ()
         (local (defalist string-integer-list-alist-p (x)
                  :key (stringp x)
                  :val (integer-listp x)
                  :keyp-of-nil nil
                  :valp-of-nil t))))


;; basic true-listp testing...

(local (encapsulate ()
         (local (defalist true-string-int-alistp (x)
                  :key (stringp x)
                  :val (integerp x)
                  :true-listp t))))

(local (encapsulate ()
         (local (defalist true-string-int-alist-2p (x)
                  :key (stringp x)
                  :val (integerp x)
                  :keyp-of-nil nil
                  :true-listp t))))

(local (encapsulate ()
         (local (defalist true-string-int-alist-3p (x)
                  :key (stringp x)
                  :val (integerp x)
                  :valp-of-nil nil
                  :true-listp t))))

(local (encapsulate ()
         (local (defalist true-string-integer-list-alist-p (x)
                  :key (stringp x)
                  :val (integer-listp x)
                  :keyp-of-nil nil
                  :valp-of-nil t
                  :true-listp t))))


;; basic other-package testing...

#!ACL2
(local (encapsulate ()
         (local (std::defalist string-int-alistp (x)
                  :key (stringp x)
                  :val (integerp x)))))

#!ACL2
(local (encapsulate ()
         (local (std::defalist string-int-alistp (x)
                  :key (stringp x)
                  :val (integerp x)
                  :true-listp t))))

#!ACL2
(local (encapsulate ()
         (local (std::defalist string-int-alistp (x)
                  :key (stringp x)
                  :val (integerp x)
                  :keyp-of-nil nil
                  :valp-of-nil nil
                  :true-listp t))))


;; multi-argument testing...

(local (defun my-greater-than (x n)
         (declare (xargs :guard (integerp n)))
         (and (integerp x)
              (> x n))))

(local (encapsulate ()
         (local (defalist gt-alist (x arg)
                  :key (my-greater-than x arg)
                  :val (consp x)
                  :guard (integerp arg)
                  :keyp-of-nil nil
                  :valp-of-nil nil))))

(local (encapsulate ()
         (local (defalist gt-alist2 (x arg)
                  :key (my-greater-than x arg)
                  :val (consp x)
                  :guard (integerp arg)
                  :keyp-of-nil nil
                  :valp-of-nil nil
                  :true-listp t))))

(local (encapsulate ()
         (local (defalist gt-alist3 (x arg arg2)
                  :key (my-greater-than x arg)
                  :val (my-greater-than x arg2)
                  :guard (and (integerp arg)
                              (integerp arg2))
                  :keyp-of-nil nil
                  :valp-of-nil nil))))


;; check for special trivial sorts of things that ACL2 can rewrite in deep
;; ways.  this has screwed us up before due to restrictions on :rewrite rules,
;; etc.

(local (in-theory (theory 'minimal-theory)))

(local (defun anyp (x)
         (declare (ignore x)
                  (xargs :guard t))
         t))

(local (defun nonep (x)
         (declare (ignore x)
                  (xargs :guard t))
         nil))

(local (encapsulate ()
         (local (defalist any-none-alistp (x)
                  :key (anyp x)
                  :val (nonep x)))))

(local (encapsulate ()
         (local (defalist none-any-alistp (x)
                  :key (nonep x)
                  :val (anyp x)))))

(local (encapsulate ()
         (local (defalist any-none-alistp2 (x)
                  :key (anyp x)
                  :val (nonep x)
                  :keyp-of-nil t
                  :valp-of-nil nil))))

(local (encapsulate ()
         (local (defalist none-any-alistp2 (x)
                  :key (nonep x)
                  :val (anyp x)
                  :keyp-of-nil nil
                  :valp-of-nil t))))



;; an extra hard case due to irritating stupid awful "simplify rule, then
;; reject simplified rule for being too simple" stuff

(local (encapsulate ()
         (local (defalist null-not-alist (x)
                  :key (null x)
                  :val (not x)
                  :keyp-of-nil t
                  :valp-of-nil t))))


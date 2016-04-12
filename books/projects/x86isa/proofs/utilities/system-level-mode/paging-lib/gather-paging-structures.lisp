;; AUTHOR:
;; Shilpi Goel <shigoel@cs.utexas.edu>

(in-package "X86ISA")
(include-book "paging-basics")
(include-book "clause-processors/find-subterms" :dir :system)

(local (include-book "centaur/bitops/ihs-extensions" :dir :system))
(local (include-book "centaur/bitops/signed-byte-p" :dir :system))
(local (include-book "std/lists/remove-duplicates" :dir :system))

;; ======================================================================

(defsection gather-paging-structures
  :parents (reasoning-about-page-tables)

  :short "Gather physical addresses where paging data structures are located"

  :long "<p>WORK IN PROGRESS...</p>

<p>This doc topic will be updated in later commits...</p>"
  )

;; ======================================================================

;; Some misc. lemmas:

(defthmd loghead-smaller-and-logbitp
  (implies (and (equal (loghead n e-1) (loghead n e-2))
                (natp n)
                (natp m)
                (< m n))
           (equal (logbitp m e-1) (logbitp m e-2)))
  :hints (("Goal" :in-theory (e/d* (bitops::ihsext-inductions
                                    bitops::ihsext-recursive-redefs)
                                   ()))))

(defthmd logtail-bigger
  (implies (and (equal (logtail m e-1) (logtail m e-2))
                (integerp e-2)
                (natp n)
                (<= m n))
           (equal (logtail n e-1) (logtail n e-2)))
  :hints (("Goal" :in-theory (e/d* (bitops::ihsext-inductions
                                    bitops::ihsext-recursive-redefs)
                                   ()))))

(defthmd logtail-bigger-and-logbitp
  (implies (and (equal (logtail m e-1) (logtail m e-2))
                (integerp e-2)
                (natp n)
                (<= m n))
           (equal (logbitp n e-1) (logbitp n e-2)))
  :hints (("Goal" :in-theory (e/d* (bitops::ihsext-inductions
                                    bitops::ihsext-recursive-redefs)
                                   ()))))

(defthm member-list-p-no-duplicates-list-p-and-member-p
  (implies (and (member-list-p index addrs-2)
                (true-listp addrs-1)
                (true-list-listp addrs-2)
                (no-duplicates-list-p (append (list addrs-1) addrs-2)))
           (not (member-p index addrs-1)))
  :hints (("Goal" :in-theory (e/d* (member-p
                                    member-list-p
                                    acl2::flatten
                                    no-duplicates-p)
                                   ()))))

;; (local (include-book "ihs/logops-lemmas" :dir :system))

;; (defthmd loghead-logtail-bigger-and-logbitp
;;   (implies (and (equal (loghead n (logtail m e-1))
;;                        (loghead n (logtail m e-2)))
;;                 (natp e-1)
;;                 (natp e-2)
;;                 (natp p)
;;                 (natp m)
;;                 (natp n)
;;                 (<= m p)
;;                 (< p (+ m n)))
;;            (equal (logbitp p e-1) (logbitp p e-2)))
;;   :hints (("Goal"
;;            :in-theory (e/d* (bitops::ihsext-inductions
;;                              bitops::ihsext-recursive-redefs)
;;                             ()))
;;           ("Subgoal *1/6"
;;            :use ((:instance loghead-smaller-and-logbitp
;;                             (n n)
;;                             (m p))))
;;           ("Subgoal *1/2"
;;            :use ((:instance loghead-smaller-and-logbitp
;;                             (n n)
;;                             (m p))))))

;; ======================================================================

(define qword-paddr-listp (xs)
  :parents (reasoning-about-page-tables)
  :enabled t
  :short "Recognizer for a list of physical addresses that can
  accommodate a quadword"
  (if (consp xs)
      (and (physical-address-p (car xs))
           (physical-address-p (+ 7 (car xs)))
           (qword-paddr-listp (cdr xs)))
    (equal xs nil))

  ///

  (defthm qword-paddr-listp-implies-true-listp
    (implies (qword-paddr-listp xs)
             (true-listp xs))
    :rule-classes :forward-chaining)

  (defthm qword-paddr-listp-and-append
    (implies (and (qword-paddr-listp a)
                  (qword-paddr-listp b))
             (qword-paddr-listp (append a b))))

  (defthm qword-paddr-listp-and-remove-duplicates-equal
    (implies (qword-paddr-listp a)
             (qword-paddr-listp (remove-duplicates-equal a))))

  (defthm-usb qword-paddrp-element-of-qword-paddr-listp
    :hyp (and (qword-paddr-listp xs)
              (natp m)
              (< m (len xs)))
    :bound 52
    :concl (nth m xs)
    :gen-linear t
    :gen-type t)

  (defthm nthcdr-qword-paddr-listp
    (implies (qword-paddr-listp xs)
             (qword-paddr-listp (nthcdr n xs)))
    :rule-classes (:rewrite :type-prescription)))

(define qword-paddr-list-listp (xs)
  :parents (reasoning-about-page-tables)
  :enabled t
  (cond ((atom xs) (eq xs nil))
        (t (and (qword-paddr-listp (car xs))
                (qword-paddr-list-listp (cdr xs)))))

  ///

  (defthm qword-paddr-list-listp-and-remove-duplicates-equal
    (implies (qword-paddr-list-listp a)
             (qword-paddr-list-listp (remove-duplicates-equal a))))

  (defthm append-of-qword-paddr-list-listp
    (implies (and (qword-paddr-list-listp xs)
                  (qword-paddr-list-listp ys))
             (qword-paddr-list-listp (append xs ys))))

  (defthm qword-paddr-list-listp-implies-true-list-listp
    (implies (qword-paddr-list-listp xs)
             (true-list-listp xs))
    :rule-classes :forward-chaining))

(defthm append-of-true-list-listp
  (implies (and (true-list-listp xs)
                (true-list-listp ys))
           (true-list-listp (append xs ys))))

(define mult-8-qword-paddr-listp (xs)
  :enabled t
  :parents (reasoning-about-page-tables)
  :short "Recognizer for a list of physical addresses that can
  accommodate a quadword"
  (if (consp xs)
      (and (physical-address-p (car xs))
           (physical-address-p (+ 7 (car xs)))
           ;; Multiple of 8
           (equal (loghead 3 (car xs)) 0)
           (mult-8-qword-paddr-listp (cdr xs)))
    (equal xs nil))

  ///

  (defthm mult-8-qword-paddr-listp-implies-true-listp
    (implies (mult-8-qword-paddr-listp xs)
             (true-listp xs))
    :rule-classes :forward-chaining)

  (defthm mult-8-qword-paddr-listp-and-append
    (implies (and (mult-8-qword-paddr-listp a)
                  (mult-8-qword-paddr-listp b))
             (mult-8-qword-paddr-listp (append a b))))

  (defthm mult-8-qword-paddr-listp-remove-duplicates-equal
    (implies (mult-8-qword-paddr-listp addrs)
             (mult-8-qword-paddr-listp (remove-duplicates-equal addrs))))

  (defthm-usb qword-paddrp-element-of-mult-8-qword-paddr-listp
    :hyp (and (mult-8-qword-paddr-listp xs)
              (natp m)
              (< m (len xs)))
    :bound 52
    :concl (nth m xs)
    :gen-linear t
    :gen-type t)

  (local (include-book "std/lists/nthcdr" :dir :system))

  (defthm nthcdr-mult-8-qword-paddr-listp
    (implies (mult-8-qword-paddr-listp xs)
             (mult-8-qword-paddr-listp (nthcdr n xs)))
    :rule-classes (:rewrite :type-prescription))

  (defthm member-p-and-mult-8-qword-paddr-listp
    (implies (and (member-p index addrs)
                  (mult-8-qword-paddr-listp addrs))
             (and (physical-address-p index)
                  (equal (loghead 3 index) 0)))
    :rule-classes (:rewrite :forward-chaining)))

(encapsulate
 ()

 (local
  (defthm open-addr-range
    (implies (natp x)
             (equal (addr-range 8 x)
                    (list x (+ 1 x) (+ 2 x) (+ 3 x)
                          (+ 4 x) (+ 5 x) (+ 6 x) (+ 7 x))))))

 (local
  (encapsulate
   ()

   (local (include-book "arithmetic-5/top" :dir :system))

   (defthm multiples-of-8-and-disjointness-of-physical-addresses-helper-1
     (implies (and (equal (loghead 3 x) 0)
                   (equal (loghead 3 y) 0)
                   (posp n)
                   (<= n 7)
                   (natp x)
                   (natp y))
              (not (equal (+ n x) y)))
     :hints (("Goal" :in-theory (e/d* (loghead)
                                      ()))))

   (defthm multiples-of-8-and-disjointness-of-physical-addresses-helper-2
     (implies (and (equal (loghead 3 x) 0)
                   (equal (loghead 3 y) 0)
                   (not (equal x y))
                   (posp n)
                   (<= n 7)
                   (posp m)
                   (<= m 7)
                   (natp x)
                   (natp y))
              (not (equal (+ n x) (+ m y))))
     :hints (("Goal" :in-theory (e/d* (loghead)
                                      ()))))))

 (defthm multiples-of-8-and-disjointness-of-physical-addresses-1
   (implies (and (equal (loghead 3 addr-1) 0)
                 (equal (loghead 3 addr-2) 0)
                 (not (equal addr-2 addr-1))
                 (natp addr-1)
                 (natp addr-2))
            (disjoint-p (addr-range 8 addr-2)
                        (addr-range 8 addr-1))))

 (defthm multiples-of-8-and-disjointness-of-physical-addresses-2
   (implies (and (equal (loghead 3 addr-1) 0)
                 (equal (loghead 3 addr-2) 0)
                 (not (equal addr-2 addr-1))
                 (natp addr-1)
                 (natp addr-2))
            (disjoint-p (cons addr-2 nil)
                        (addr-range 8 addr-1))))

 (defthm mult-8-qword-paddr-listp-and-disjoint-p
   (implies (and (member-p index addrs)
                 (mult-8-qword-paddr-listp (cons addr addrs))
                 (no-duplicates-p (cons addr addrs)))
            (disjoint-p (addr-range 8 index)
                        (addr-range 8 addr)))
   :hints (("Goal" :in-theory (e/d* () (open-addr-range))))
   :rule-classes :forward-chaining))

(define mult-8-qword-paddr-list-listp (xs)
  :parents (reasoning-about-page-tables)
  :enabled t
  (cond ((atom xs) (eq xs nil))
        (t (and (mult-8-qword-paddr-listp (car xs))
                (mult-8-qword-paddr-list-listp (cdr xs)))))

  ///

  (defthm mult-8-qword-paddr-list-listp-remove-duplicates-equal
    (implies (mult-8-qword-paddr-list-listp addrs)
             (mult-8-qword-paddr-list-listp (remove-duplicates-equal addrs))))

  (defthm append-of-mult-8-qword-paddr-list-listp
    (implies (and (mult-8-qword-paddr-list-listp xs)
                  (mult-8-qword-paddr-list-listp ys))
             (mult-8-qword-paddr-list-listp (append xs ys))))

  (defthm mult-8-qword-paddr-list-listp-implies-true-list-listp
    (implies (mult-8-qword-paddr-list-listp xs)
             (true-list-listp xs))
    :rule-classes :forward-chaining)

  (defthm mult-8-qword-paddr-list-listp-and-append-1
    (implies (and (mult-8-qword-paddr-list-listp (append x y))
                  (true-listp x))
             (mult-8-qword-paddr-list-listp x))
    :rule-classes (:rewrite :forward-chaining))

  (defthm mult-8-qword-paddr-list-listp-and-append-2
    (implies (mult-8-qword-paddr-list-listp (append x y))
             (mult-8-qword-paddr-list-listp y))
    :rule-classes (:rewrite :forward-chaining))

  (defthm member-list-p-and-mult-8-qword-paddr-list-listp
    (implies (and (member-list-p index addrs)
                  (mult-8-qword-paddr-list-listp addrs))
             (and (physical-address-p index)
                  (equal (loghead 3 index) 0)))
    :rule-classes (:rewrite :forward-chaining)))

(define open-qword-paddr-list (xs)
  :guard (qword-paddr-listp xs)
  :enabled t
  (if (endp xs)
      nil
    (append (addr-range 8 (car xs))
            (open-qword-paddr-list (cdr xs))))
  ///

  (defthm open-qword-paddr-list-and-member-p
    (implies (and (mult-8-qword-paddr-listp addrs)
                  (member-p index addrs))
             (member-p index (open-qword-paddr-list addrs)))
    :hints (("Goal" :in-theory (e/d* (member-p) ()))))

  (defthm open-qword-paddr-list-and-append
    (equal (open-qword-paddr-list (append xs ys))
           (append (open-qword-paddr-list xs)
                   (open-qword-paddr-list ys)))))

(define open-qword-paddr-list-list (xs)
  :guard (qword-paddr-list-listp xs)
  :enabled t
  (if (endp xs)
      nil
    (cons (open-qword-paddr-list (car xs))
          (open-qword-paddr-list-list (cdr xs))))
  ///

  (defthm open-qword-paddr-list-list-and-member-list-p
    (implies (and (mult-8-qword-paddr-list-listp addrs)
                  (member-list-p index addrs))
             (member-list-p index (open-qword-paddr-list-list addrs)))
    :hints (("Goal" :in-theory (e/d* (member-list-p member-p) ()))))

  (defthm open-qword-paddr-list-list-and-append
    (equal (open-qword-paddr-list-list (append xs ys))
           (append (open-qword-paddr-list-list xs)
                   (open-qword-paddr-list-list ys))))

  (defthm open-qword-paddr-list-list-pairwise-disjoint-p-aux-and-disjoint-p
    (implies (and
              (pairwise-disjoint-p-aux (list index) (open-qword-paddr-list-list addrs))
              (member-list-p entry-addr addrs))
             (disjoint-p (list index) (addr-range 8 entry-addr)))
    :hints (("Goal" :in-theory (e/d* (pairwise-disjoint-p-aux)
                                     ()))))

  (defthm open-qword-paddr-list-list-pairwise-disjoint-p-aux-and-member-p
    (implies (and (pairwise-disjoint-p-aux (list index) (open-qword-paddr-list-list addrs))
                  (member-list-p entry-addr addrs))
             (not (member-p index (addr-range 8 entry-addr))))
    :hints (("Goal" :in-theory (e/d* (pairwise-disjoint-p-aux) ())))))

(define create-qword-address-list
  ((count natp)
   (addr :type (unsigned-byte #.*physical-address-size*)))

  :parents (reasoning-about-page-tables)
  :guard (physical-address-p (+ -1 (ash count 3) addr))

  :prepwork
  ((local (include-book "arithmetic-5/top" :dir :system))

   (local (in-theory (e/d* (ash unsigned-byte-p) ())))

   (defthm-usb n52p-left-shifting-a-40-bit-natp-by-12
     :hyp (unsigned-byte-p 40 x)
     :bound 52
     :concl (+ 4095 (ash x 12)))

   (defthm-usb n52p-left-shifting-a-40-bit-natp-by-12-+-7
     :hyp (unsigned-byte-p 40 x)
     :bound 52
     :concl (+ 7 (ash x 12)))

   (defthm loghead-3-+8-addr
     (implies (equal (loghead 3 addr) 0)
              (equal (loghead 3 (+ 8 addr)) 0))
     :hints (("Goal" :in-theory (e/d* (bitops::ihsext-inductions
                                       bitops::ihsext-recursive-redefs
                                       loghead
                                       ifix)
                                      ())))))

  :enabled t

  (if (or (zp count)
          (not (physical-address-p addr))
          (not (physical-address-p (+ 7 addr))))
      nil
    (if (equal count 1)
        (list addr)
      (cons addr (create-qword-address-list (1- count) (+ 8 addr)))))

  ///

  (defthm nat-listp-create-qword-address-list
    (nat-listp (create-qword-address-list count addr))
    :rule-classes :type-prescription)

  (defthm qword-paddr-listp-create-qword-address-list
    (qword-paddr-listp (create-qword-address-list count addr)))

  (defthm mult-8-qword-paddr-listp-create-qword-address-list
    (implies (equal (loghead 3 addr) 0)
             (mult-8-qword-paddr-listp (create-qword-address-list count addr))))

  (defthm create-qword-address-list-1
    (implies (and (physical-address-p (+ 7 addr))
                  (physical-address-p addr))
             (equal (create-qword-address-list 1 addr)
                    (list addr)))
    :hints (("Goal" :expand (create-qword-address-list 1 addr))))

  (defthm non-nil-create-qword-address-list
    (implies (and (posp count)
                  (physical-address-p addr)
                  (physical-address-p (+ 7 addr)))
             (create-qword-address-list count addr)))

  (defthm consp-create-qword-address-list
    (implies (and (physical-address-p addr)
                  (physical-address-p (+ 7 addr))
                  (posp count))
             (consp (create-qword-address-list count addr)))
    :rule-classes (:type-prescription :rewrite))

  (defthm car-of-create-qword-address-list
    (implies (and (posp count)
                  (physical-address-p addr)
                  (physical-address-p (+ 7 addr)))
             (equal (car (create-qword-address-list count addr))
                    addr)))

  (defthm member-p-create-qword-address-list
    (implies (and (<= addr x)
                  (< x (+ (ash count 3) addr))
                  (equal (loghead 3 addr) 0)
                  (equal (loghead 3 x) 0)
                  (physical-address-p x)
                  (physical-address-p addr))
             (equal (member-p x (create-qword-address-list count addr))
                    t))
    :hints (("Goal"
             :induct (create-qword-address-list count addr)
             :in-theory (e/d* (loghead) ()))))

  (defthm not-member-p-create-qword-address-list
    (implies (or (not (<= addr x))
                 (not (< x (+ (ash count 3) addr))))
             (equal (member-p x (create-qword-address-list count addr))
                    nil))
    :hints (("Goal"
             :induct (create-qword-address-list count addr)
             :in-theory (e/d* (loghead) ()))))

  (defthm no-duplicates-p-create-qword-address-list
    (no-duplicates-p (create-qword-address-list count addr))))

(local (in-theory (e/d* () (unsigned-byte-p))))

;; ======================================================================

(define xlate-equiv-entries
  ((e-1 :type (unsigned-byte 64))
   (e-2 :type (unsigned-byte 64)))
  :parents (xlate-equiv-structures)
  :long "<p>Two paging structure entries are @('xlate-equiv-entries')
  if they are equal for all bits except the accessed and dirty
  bits (bits 5 and 6, respectively).</p>"
  (and (equal (part-select e-1 :low 0 :high 4)
              (part-select e-2 :low 0 :high 4))
       ;; Bits 5 (accessed bit) and 6 (dirty bit) missing here.
       (equal (part-select e-1 :low 7 :high 63)
              (part-select e-2 :low 7 :high 63)))
  ///
  (defequiv xlate-equiv-entries)

  (defthm xlate-equiv-entries-self-set-accessed-bit
    (and (xlate-equiv-entries e (set-accessed-bit (double-rewrite e)))
         (xlate-equiv-entries (set-accessed-bit e) (double-rewrite e)))
    :hints (("Goal" :in-theory (e/d* (set-accessed-bit) ()))))

  (defthm xlate-equiv-entries-self-set-dirty-bit
    (and (xlate-equiv-entries e (set-dirty-bit (double-rewrite e)))
         (xlate-equiv-entries (set-dirty-bit e) (double-rewrite e)))
    :hints (("Goal" :in-theory (e/d* (set-dirty-bit) ()))))

  (defun find-xlate-equiv-entries (e-1-equiv e-2-equiv)
    ;; [Shilpi]: This is a quick and dirty function to bind the
    ;; free-vars of
    ;; xlate-equiv-entries-and-set-accessed-and/or-dirty-bit. It makes
    ;; the assumption that e-1-equiv and e-2-equiv will have one of the
    ;; following forms:

    ;; e-1-equiv == e-2-equiv (any form as long as they're both equal)
    ;; (set-accessed-bit (rm-low-64 index x86))
    ;; (set-dirty-bit (rm-low-64 index x86))
    ;; (set-accessed-bit (set-dirty-bit (rm-low-64 index x86)))
    ;; (set-dirty-bit (set-accessed-bit (rm-low-64 index x86)))

    ;; I haven't considered deeper nesting of set-accessed-bit and
    ;; set-dirty-bit, mainly because at this point, I'm reasonably
    ;; confident that that's a situation that won't occur.
    (cond ((equal e-1-equiv e-2-equiv)
           `((e-1 . ,e-1-equiv)
             (e-2 . ,e-2-equiv)))
          ((equal (first e-1-equiv) 'rm-low-64)
           (cond ((equal (first e-2-equiv) 'rm-low-64)
                  `((e-1 . ,e-1-equiv)
                    (e-2 . ,e-2-equiv)))
                 ((equal (first e-2-equiv) 'set-accessed-bit)
                  (b* ((e-2
                        (if (equal (car (second e-2-equiv)) 'set-dirty-bit)
                            (second (second e-2-equiv))
                          (second e-2-equiv))))
                    `((e-1 . ,e-1-equiv)
                      (e-2 . ,e-2))))
                 ((equal (first e-2-equiv) 'set-dirty-bit)
                  (b* ((e-2
                        (if (equal (car (second e-2-equiv)) 'set-accessed-bit)
                            (second (second e-2-equiv))
                          (second (second e-2-equiv)))))
                    `((e-1 . ,e-1-equiv)
                      (e-2 . ,e-2))))
                 (t
                  `((e-1 . ,e-1-equiv)
                    (e-2 . ,e-2-equiv)))))
          ((equal (first e-2-equiv) 'rm-low-64)
           (cond ((equal (first e-1-equiv) 'rm-low-64)
                  `((e-2 . ,e-2-equiv)
                    (e-1 . ,e-1-equiv)))
                 ((equal (first e-1-equiv) 'set-accessed-bit)
                  (b* ((e-1
                        (if (equal (car (second e-1-equiv)) 'set-dirty-bit)
                            (second (second e-1-equiv))
                          (second e-1-equiv))))
                    `((e-2 . ,e-2-equiv)
                      (e-1 . ,e-1))))
                 ((equal (first e-1-equiv) 'set-dirty-bit)
                  (b* ((e-1
                        (if (equal (car (second e-1-equiv)) 'set-accessed-bit)
                            (second (second e-1-equiv))
                          (second e-1-equiv))))
                    `((e-2 . ,e-2-equiv)
                      (e-1 . ,e-1))))
                 (t
                  `((e-2 . ,e-2-equiv)
                    (e-1 . ,e-1-equiv)))))))

  (defthm xlate-equiv-entries-and-set-accessed-and/or-dirty-bit
    (implies
     (and (bind-free (find-xlate-equiv-entries e-1-equiv e-2-equiv) (e-1 e-2))
          (xlate-equiv-entries e-1 e-2)
          (or (equal e-1-equiv e-1)
              (equal e-1-equiv (set-accessed-bit e-1))
              (equal e-1-equiv (set-dirty-bit e-1))
              (equal e-1-equiv
                     (set-dirty-bit (set-accessed-bit e-1))))
          (or (equal e-2-equiv e-2)
              (equal e-2-equiv (set-accessed-bit e-2))
              (equal e-2-equiv (set-dirty-bit e-2))
              (equal e-2-equiv
                     (set-dirty-bit (set-accessed-bit e-2)))))
     (xlate-equiv-entries e-1-equiv e-2-equiv))
    :hints (("Goal" :in-theory (e/d* (set-accessed-bit
                                      set-dirty-bit)
                                     ()))))

  (defthmd xlate-equiv-entries-and-loghead
    (implies (and (xlate-equiv-entries e-1 e-2)
                  (syntaxp (quotep n))
                  (natp n)
                  (<= n 5))
             (equal (loghead n e-1) (loghead n e-2)))
    :hints (("Goal" :use ((:instance loghead-smaller-equality
                                     (x e-1) (y e-2) (n 5) (m n))))))

  (defthm xlate-equiv-entries-and-page-present
    (implies (xlate-equiv-entries e-1 e-2)
             (equal (page-present e-1) (page-present e-2)))
    :hints (("Goal"
             :use ((:instance xlate-equiv-entries-and-loghead
                              (e-1 e-1) (e-2 e-2) (n 1)))
             :in-theory (e/d* (page-present) ())))
    :rule-classes :congruence)

  (defthm xlate-equiv-entries-and-page-read-write
    (implies (xlate-equiv-entries e-1 e-2)
             (equal (page-read-write e-1) (page-read-write e-2)))
    :hints (("Goal"
             :use ((:instance loghead-smaller-and-logbitp
                              (e-1 e-1) (e-2 e-2) (m 1) (n 5)))
             :in-theory (e/d* (page-read-write) ())))
    :rule-classes :congruence)

  (defthm xlate-equiv-entries-and-page-user-supervisor
    (implies (xlate-equiv-entries e-1 e-2)
             (equal (page-user-supervisor e-1) (page-user-supervisor e-2)))
    :hints (("Goal"
             :use ((:instance loghead-smaller-and-logbitp
                              (e-1 e-1) (e-2 e-2) (m 2) (n 5)))
             :in-theory (e/d* (page-user-supervisor) ())))
    :rule-classes :congruence)

  (defthmd xlate-equiv-entries-and-logtail
    (implies (and (xlate-equiv-entries e-1 e-2)
                  (unsigned-byte-p 64 e-1)
                  (unsigned-byte-p 64 e-2)
                  (syntaxp (quotep n))
                  (natp n)
                  (<= 7 n)
                  (< n 64))
             (equal (logtail n e-1) (logtail n e-2)))
    :hints (("Goal" :use ((:instance logtail-bigger (n n) (m 7))))))

  (defthmd xlate-equiv-entries-and-page-size
    (implies (and (xlate-equiv-entries e-1 e-2)
                  (unsigned-byte-p 64 e-1)
                  (unsigned-byte-p 64 e-2))
             (equal (page-size e-1) (page-size e-2)))
    :hints (("Goal"
             :use ((:instance logtail-bigger-and-logbitp
                              (e-1 e-1) (e-2 e-2) (m 7) (n 7)))
             :in-theory (e/d* (page-size) ()))))

  (defthmd xlate-equiv-entries-and-page-execute-disable
    (implies (and (xlate-equiv-entries e-1 e-2)
                  (unsigned-byte-p 64 e-1)
                  (unsigned-byte-p 64 e-2))
             (equal (page-execute-disable e-1) (page-execute-disable e-2)))
    :hints (("Goal"
             :use ((:instance logtail-bigger-and-logbitp
                              (e-1 e-1) (e-2 e-2) (m 7) (n 63)))
             :in-theory (e/d* (page-execute-disable) ()))))

  (defthm xlate-equiv-entries-with-loghead-64
    (implies (xlate-equiv-entries e-1 e-2)
             (xlate-equiv-entries (loghead 64 e-1) (loghead 64 e-2)))
    :rule-classes :congruence))

;; ======================================================================

;; Gathering the physical addresses where paging structures are
;; located:

(define gather-pml4-table-qword-addresses (x86)
  :parents (gather-paging-structures)
  :returns (list-of-addresses qword-paddr-listp)

  (b* ((cr3 (ctri *cr3* x86))
       ;; PML4 Table, all 4096 bytes of it, will always fit into the
       ;; physical memory; pml4-table-base-addr is 52-bit wide, with
       ;; low 12 bits = 0.
       (pml4-table-base-addr (ash (cr3-slice :cr3-pdb cr3) 12)))
    (create-qword-address-list 512 pml4-table-base-addr))
  ///
  (std::more-returns (list-of-addresses true-listp))

  (defthm consp-gather-pml4-table-qword-addresses
    (consp (gather-pml4-table-qword-addresses x86))
    :rule-classes (:type-prescription :rewrite))

  (defthm mult-8-qword-paddr-listp-gather-pml4-table-qword-addresses
    (mult-8-qword-paddr-listp (gather-pml4-table-qword-addresses x86)))

  (defthm no-duplicates-p-gather-pml4-table-qword-addresses
    (no-duplicates-p (gather-pml4-table-qword-addresses x86)))

  (defthm gather-pml4-table-qword-addresses-xw-fld!=ctr
    (implies (not (equal fld :ctr))
             (equal (gather-pml4-table-qword-addresses (xw fld index val x86))
                    (gather-pml4-table-qword-addresses x86)))
    :hints (("Goal"
             :cases ((equal fld :ctr))
             :in-theory (e/d* (gather-pml4-table-qword-addresses)
                              ()))))

  (defthm gather-pml4-table-qword-addresses-wm-low-64
    (equal (gather-pml4-table-qword-addresses (wm-low-64 index val x86))
           (gather-pml4-table-qword-addresses x86))
    :hints (("Goal"
             :in-theory (e/d* (gather-pml4-table-qword-addresses)
                              ()))))

  (defthm gather-pml4-table-qword-addresses-xw-fld=ctr
    (implies (and (equal fld :ctr)
                  (not (equal index *cr3*)))
             (equal (gather-pml4-table-qword-addresses (xw fld index val x86))
                    (gather-pml4-table-qword-addresses x86)))
    :hints (("Goal"
             :cases ((equal fld :ctr))
             :in-theory (e/d* (gather-pml4-table-qword-addresses)
                              ())))))

(define gather-qword-addresses-corresponding-to-1-entry
  ((superior-structure-paddr natp)
   x86)

  :parents (gather-paging-structures)

  :guard (and (not (xr :programmer-level-mode 0 x86))
              (physical-address-p superior-structure-paddr)
              (physical-address-p (+ 7 superior-structure-paddr)))

  :returns (list-of-addresses qword-paddr-listp)

  :short "Returns a list of all the qword addresses of the inferior
  paging structure referred by a paging entry at address
  @('superior-structure-paddr')"

  (b* ((superior-structure-entry (rm-low-64 superior-structure-paddr x86)))
    (if (and
         (equal (page-present  superior-structure-entry) 1)
         (equal (page-size superior-structure-entry) 0))
        ;; Gather the qword addresses of a paging structure only if a
        ;; superior structure points to it, i.e., the
        ;; superior-structure-entry should be present (P=1) and it
        ;; should reference an inferior structure (PS=0).
        (b* ((this-structure-base-addr
              (ash (ia32e-page-tables-slice
                    :reference-addr superior-structure-entry) 12))
             ;; The inferior table will always fit into the physical
             ;; memory.
             )
          (create-qword-address-list 512 this-structure-base-addr))
      nil))
  ///
  (std::more-returns (list-of-addresses true-listp))

  (defthm mult-8-qword-paddr-listp-gather-qword-addresses-corresponding-to-1-entry
    (mult-8-qword-paddr-listp
     (gather-qword-addresses-corresponding-to-1-entry entry x86)))

  (defthm no-duplicates-p-gather-qword-addresses-corresponding-to-1-entry
    (no-duplicates-p
     (gather-qword-addresses-corresponding-to-1-entry entry x86)))

  (defthm gather-qword-addresses-corresponding-to-1-entry-xw-fld!=mem
    (implies (and (not (equal fld :mem))
                  (not (equal fld :programmer-level-mode)))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     n (xw fld index val x86))
                    (gather-qword-addresses-corresponding-to-1-entry n x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-xw-fld=mem-disjoint
    (implies (disjoint-p (addr-range 1 index)
                         (addr-range 8 addr))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     addr (xw :mem index val x86))
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                              (addr-range
                               addr-range-1)))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-wm-low-64-disjoint
    (implies (and (disjoint-p (addr-range 8 index)
                              (addr-range 8 addr))
                  (physical-address-p index)
                  (physical-address-p addr))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     addr (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-wm-low-64-superior-entry-addr
    (implies (and (equal index addr)
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 addr x86))
                  (unsigned-byte-p 64 val)
                  (physical-address-p index)
                  (physical-address-p (+ 7 index))
                  (not (xr :programmer-level-mode 0 x86))
                  (x86p x86))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     addr (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal"
             :in-theory (e/d* (member-p)
                              (xlate-equiv-entries))
             :use ((:instance xlate-equiv-entries-and-page-present
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-page-size
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-logtail
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86))
                              (n 12))))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-with-different-x86-entries
    (implies (and (xlate-equiv-entries (rm-low-64 addr x86-equiv)
                                       (rm-low-64 addr x86))
                  (x86p x86)
                  (x86p x86-equiv))
             (equal (gather-qword-addresses-corresponding-to-1-entry addr x86-equiv)
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                                     (unsigned-byte-p))
             :use ((:instance xlate-equiv-entries-and-page-size
                              (e-1 (rm-low-64 addr x86-equiv))
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-page-present
                              (e-1 (rm-low-64 addr x86-equiv))
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-logtail
                              (e-1 (rm-low-64 addr x86-equiv))
                              (e-2 (rm-low-64 addr x86))
                              (n 12))))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-wm-low-64-with-different-x86-disjoint
    (implies (and (disjoint-p (addr-range 8 index) (addr-range 8 addr))
                  (physical-address-p addr)
                  (physical-address-p index)
                  (equal (gather-qword-addresses-corresponding-to-1-entry addr x86-equiv)
                         (gather-qword-addresses-corresponding-to-1-entry addr x86)))
             ;; (xlate-equiv-entries (rm-low-64 addr x86-equiv)
             ;;                      (rm-low-64 addr x86))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     addr (wm-low-64 index val x86-equiv))
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                                     (gather-qword-addresses-corresponding-to-1-entry-wm-low-64-disjoint
                                      unsigned-byte-p))
             :use ((:instance gather-qword-addresses-corresponding-to-1-entry-wm-low-64-disjoint
                              (x86 x86-equiv))))))

  (defthm gather-qword-addresses-corresponding-to-1-entry-wm-low-64-with-different-x86
    ;; This is a surprising theorem. Even if we write an
    ;; xlate-equiv-entries value to addr in x86-equiv (a state that may
    ;; be different from x86), there's no guarantee that the qword
    ;; addresses of the inferior structure entry pointed to by this new
    ;; value will be the same in x86 and x86-equiv. However, that's
    ;; exactly what this theorem says, and this is because of the way
    ;; gather-qword-addresses-corresponding-to-1-entry is defined ---
    ;; simply in terms of create-qword-address-list once the entry at
    ;; addr is read from the x86 (or x86-equiv) state.
    (implies (and (xlate-equiv-entries (double-rewrite val) (rm-low-64 addr x86))
                  (unsigned-byte-p 64 val)
                  (physical-address-p addr)
                  (physical-address-p (+ 7 addr))
                  (x86p x86)
                  (not (xr :programmer-level-mode 0 x86-equiv)))
             (equal (gather-qword-addresses-corresponding-to-1-entry
                     addr (wm-low-64 addr val x86-equiv))
                    (gather-qword-addresses-corresponding-to-1-entry addr x86)))
    :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry)
                                     ())
             :use ((:instance xlate-equiv-entries-and-page-size
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-page-present
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86)))
                   (:instance xlate-equiv-entries-and-logtail
                              (e-1 val)
                              (e-2 (rm-low-64 addr x86))
                              (n 12)))))))


;; (local
;;  (defthm member-p-member-list-p-mult-8-qword-paddr-list-listp-lemma
;;    (implies (and (member-list-p index (cdr addrs))
;;                  (mult-8-qword-paddr-list-listp addrs)
;;                  (no-duplicates-list-p addrs))
;;             (not (member-p index (car addrs))))
;;    :hints (("Goal" :in-theory (e/d* (disjoint-p
;;                                      member-list-p
;;                                      member-p)
;;                                     ())))))

(local
 (defthm member-p-mult-8-qword-paddr-listp-lemma
   (implies (and (mult-8-qword-paddr-listp addrs)
                 (not (member-p index addrs))
                 (physical-address-p index)
                 (equal (loghead 3 index) 0))
            (disjoint-p (addr-range 8 index)
                        (open-qword-paddr-list addrs)))
   :hints (("Goal" :in-theory (e/d* (disjoint-p
                                     member-p)
                                    ())))))

(local
 (defthm member-p-no-duplicates-p-lemma
   (implies (and (member-p index (cdr addrs))
                 (no-duplicates-p addrs))
            (not (equal index (car addrs))))))

;; (local
;;  (defthm member-list-p-mult-8-qword-paddr-list-listp-lemma
;;    (implies (and (mult-8-qword-paddr-list-listp addrs)
;;                  (not (member-list-p index addrs))
;;                  (physical-address-p index)
;;                  (equal (loghead 3 index) 0))
;;             (pairwise-disjoint-p-aux
;;              (addr-range 8 index)
;;              (open-qword-paddr-list-list addrs)))
;;    :hints (("Goal" :in-theory (e/d* (open-qword-paddr-list-list
;;                                      member-list-p)
;;                                     ())))))

(define gather-qword-addresses-corresponding-to-entries-aux
  (superior-structure-paddrs x86)

  :parents (gather-qword-addresses-corresponding-to-entries)

  :guard (and (not (xr :programmer-level-mode 0 x86))
              (qword-paddr-listp superior-structure-paddrs))

  :short "Returns a list of qword addresses of inferior paging
  structures referred by the entries located at addresses
  @('superior-structure-paddrs') of a given superior structure"

  :returns (list-of-addresses qword-paddr-listp)

  (if (endp superior-structure-paddrs)
      nil
    (b* ((superior-structure-paddr-1 (car superior-structure-paddrs))
         (superior-structure-paddrs-rest (cdr superior-structure-paddrs))
         (inferior-addresses
          (gather-qword-addresses-corresponding-to-1-entry
           superior-structure-paddr-1 x86))
         ((when (not inferior-addresses))
          (gather-qword-addresses-corresponding-to-entries-aux
           superior-structure-paddrs-rest x86)))
      (append
       inferior-addresses
       (gather-qword-addresses-corresponding-to-entries-aux
        superior-structure-paddrs-rest x86))))
  ///
  (std::more-returns (list-of-addresses true-listp))

  (defthm mult-8-qword-paddr-listp-gather-qword-addresses-corresponding-to-entries-aux
    (implies (mult-8-qword-paddr-listp addrs)
             (mult-8-qword-paddr-listp
              (gather-qword-addresses-corresponding-to-entries-aux addrs x86))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-xw-fld!=mem
    (implies (and (not (equal fld :mem))
                  (not (equal fld :programmer-level-mode)))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (xw fld index val x86))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-xw-fld=mem-disjoint
    (implies (and (not (member-p index (open-qword-paddr-list addrs)))
                  (physical-address-p index))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (xw :mem index val x86))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux
                               ifix
                               pairwise-disjoint-p
                               disjoint-p)
                              (addr-range
                               (addr-range))))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-wm-low-64-disjoint
    (implies (and (disjoint-p (addr-range 8 index) (open-qword-paddr-list addrs))
                  (physical-address-p index)
                  (mult-8-qword-paddr-listp addrs))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux
                               ifix)
                              ()))))

  (local
   (defthm gather-qword-addresses-corresponding-to-entries-aux-wm-low-64-superior-entry-addr-helper-2
     (implies (and (member-p index addrs)
                   (mult-8-qword-paddr-listp addrs)
                   (no-duplicates-p addrs)
                   (xlate-equiv-entries val (rm-low-64 index x86))
                   (unsigned-byte-p 64 val)
                   (physical-address-p index)
                   (x86p x86)
                   (not (xr :programmer-level-mode 0 x86)))
              (equal (gather-qword-addresses-corresponding-to-entries-aux
                      addrs (wm-low-64 index val x86))
                     (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
     :hints (("Goal"
              :in-theory (e/d* (member-p) (xlate-equiv-entries))))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-wm-low-64-superior-entry-addr
    (implies (and (member-p index addrs)
                  (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (xlate-equiv-entries val (rm-low-64 index x86))
                  (unsigned-byte-p 64 val)
                  (x86p x86)
                  (not (xr :programmer-level-mode 0 x86)))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* ()
                              (xlate-equiv-entries
                               gather-qword-addresses-corresponding-to-entries-aux
                               member-p-and-mult-8-qword-paddr-listp))
             :use ((:instance member-p-and-mult-8-qword-paddr-listp
                              (index index)
                              (addrs addrs))))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-wm-low-64-with-different-x86-disjoint
    (implies (and (equal (gather-qword-addresses-corresponding-to-entries-aux addrs x86-equiv)
                         (gather-qword-addresses-corresponding-to-entries-aux addrs x86))
                  (disjoint-p (addr-range 8 index) (open-qword-paddr-list addrs))
                  (physical-address-p index)
                  (mult-8-qword-paddr-listp addrs))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (wm-low-64 index val x86-equiv))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux
                               ifix
                               pairwise-disjoint-p
                               disjoint-p)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-entries-aux-wm-low-64-with-different-x86
    (implies (and (equal (gather-qword-addresses-corresponding-to-entries-aux addrs x86-equiv)
                         (gather-qword-addresses-corresponding-to-entries-aux addrs x86))
                  (member-p index addrs)
                  (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86-equiv))
                  (unsigned-byte-p 64 val)
                  (x86p x86-equiv)
                  (not (xr :programmer-level-mode 0 x86-equiv)))
             (equal (gather-qword-addresses-corresponding-to-entries-aux
                     addrs (wm-low-64 index val x86-equiv))
                    (gather-qword-addresses-corresponding-to-entries-aux addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux
                               member-p)
                              (unsigned-byte-p))))))

(define gather-qword-addresses-corresponding-to-entries
  (superior-structure-paddrs x86)

  :parents (gather-all-paging-structure-qword-addresses)

  :guard (and (not (xr :programmer-level-mode 0 x86))
              (qword-paddr-listp superior-structure-paddrs))

  :short "Returns a list --- with no duplicates --- of qword addresses
  of inferior paging structures referred by the entries located at
  addresses @('superior-structure-paddrs') of a given superior
  structure"

  :returns (list-of-addresses qword-paddr-listp)

  (remove-duplicates-equal
   (gather-qword-addresses-corresponding-to-entries-aux
    superior-structure-paddrs x86))

  ///
  (std::more-returns (list-of-addresses true-listp))

  (defthm mult-8-qword-paddr-listp-gather-qword-addresses-corresponding-to-entries
    (implies (mult-8-qword-paddr-listp addrs)
             (mult-8-qword-paddr-listp
              (gather-qword-addresses-corresponding-to-entries addrs x86))))

  (defthm no-duplicates-p-gather-qword-addresses-corresponding-to-entries
    (no-duplicates-p
     (gather-qword-addresses-corresponding-to-entries addrs x86))
    :hints (("Goal" :in-theory (e/d* (no-duplicates-p-to-no-duplicatesp-equal)
                                     (no-duplicates-p)))))

  (defthm gather-qword-addresses-corresponding-to-entries-xw-fld!=mem
    (implies (and (not (equal fld :mem))
                  (not (equal fld :programmer-level-mode)))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (xw fld index val x86))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-entries-xw-fld=mem-disjoint
    (implies (and (not (member-p index (open-qword-paddr-list addrs)))
                  (physical-address-p index))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (xw :mem index val x86))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries
                               ifix
                               pairwise-disjoint-p
                               disjoint-p)
                              (addr-range
                               (addr-range))))))

  (defthm gather-qword-addresses-corresponding-to-entries-wm-low-64-disjoint
    (implies (and (disjoint-p (addr-range 8 index) (open-qword-paddr-list addrs))
                  (physical-address-p index)
                  (mult-8-qword-paddr-listp addrs))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries
                               ifix)
                              ()))))

  (local
   (defthm gather-qword-addresses-corresponding-to-entries-wm-low-64-superior-entry-addr-helper-2
     (implies (and (member-p index addrs)
                   (mult-8-qword-paddr-listp addrs)
                   (no-duplicates-p addrs)
                   (xlate-equiv-entries val (rm-low-64 index x86))
                   (unsigned-byte-p 64 val)
                   (x86p x86)
                   (not (xr :programmer-level-mode 0 x86)))
              (equal (gather-qword-addresses-corresponding-to-entries
                      addrs (wm-low-64 index val x86))
                     (gather-qword-addresses-corresponding-to-entries addrs x86)))
     :hints (("Goal"
              :in-theory (e/d* (member-p) (xlate-equiv-entries))))))

  (defthm gather-qword-addresses-corresponding-to-entries-wm-low-64-superior-entry-addr
    (implies (and (member-p index addrs)
                  (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (xlate-equiv-entries val (rm-low-64 index x86))
                  (unsigned-byte-p 64 val)
                  (x86p x86)
                  (not (xr :programmer-level-mode 0 x86)))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (wm-low-64 index val x86))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* ()
                              (xlate-equiv-entries
                               gather-qword-addresses-corresponding-to-entries
                               member-p-and-mult-8-qword-paddr-listp))
             :use ((:instance member-p-and-mult-8-qword-paddr-listp
                              (index index)
                              (addrs addrs))))))

  (defthm gather-qword-addresses-corresponding-to-entries-wm-low-64-with-different-x86-disjoint
    (implies (and (equal (gather-qword-addresses-corresponding-to-entries addrs x86-equiv)
                         (gather-qword-addresses-corresponding-to-entries addrs x86))
                  (disjoint-p (addr-range 8 index) (open-qword-paddr-list addrs))
                  (physical-address-p index)
                  (mult-8-qword-paddr-listp addrs))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (wm-low-64 index val x86-equiv))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries
                               ifix
                               pairwise-disjoint-p
                               disjoint-p)
                              ()))))

  (defthm gather-qword-addresses-corresponding-to-entries-wm-low-64-with-different-x86
    (implies (and (equal (gather-qword-addresses-corresponding-to-entries addrs x86-equiv)
                         (gather-qword-addresses-corresponding-to-entries addrs x86))
                  (member-p index addrs)
                  (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86-equiv))
                  (unsigned-byte-p 64 val)
                  (x86p x86-equiv)
                  (not (xr :programmer-level-mode 0 x86-equiv)))
             (equal (gather-qword-addresses-corresponding-to-entries
                     addrs (wm-low-64 index val x86-equiv))
                    (gather-qword-addresses-corresponding-to-entries addrs x86)))
    :hints (("Goal"
             :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries
                               member-p)
                              (unsigned-byte-p))))))

(defthmd member-p-iff-member-equal
  (iff (member-p e x)
       (member-equal e x))
  :hints (("Goal" :in-theory (e/d* (member-p) ()))))

(defthm member-p-of-remove-duplicates-equal
  (implies (member-p index (remove-duplicates-equal a))
           (member-p index a))
  :hints (("Goal" :in-theory (e/d* (member-p-iff-member-equal) (member-p)))))

(defthm member-p-of-open-qword-paddr-list-and-remove-duplicates-equal
  (implies (member-p index (open-qword-paddr-list (remove-duplicates-equal a)))
           (member-p index (open-qword-paddr-list a)))
  :hints (("Goal" :in-theory (e/d* (member-p) ()))))

(defthm not-member-p-of-remove-duplicates-equal
  (implies (not (member-p index (remove-duplicates-equal a)))
           (not (member-p index a)))
  :hints (("Goal" :in-theory (e/d* (member-p-iff-member-equal) (member-p)))))

(defthm not-member-p-of-open-qword-paddr-list-and-remove-duplicates-equal
  (implies (not (member-p index (open-qword-paddr-list (remove-duplicates-equal a))))
           (not (member-p index (open-qword-paddr-list a))))
  :hints (("Goal" :in-theory (e/d* (member-p) ()))))

(defthm disjoint-p-of-remove-duplicates-equal
  (implies (disjoint-p index (remove-duplicates-equal a))
           (disjoint-p index a))
  :hints (("Goal" :in-theory (e/d* (disjoint-p) ()))))

(defthm disjoint-p-of-open-qword-paddr-list-and-remove-duplicates-equal
  (implies (disjoint-p index (open-qword-paddr-list (remove-duplicates-equal a)))
           (disjoint-p index (open-qword-paddr-list a)))
  :hints (("Goal" :in-theory (e/d* (disjoint-p) ()))))

(defthm not-disjoint-p-of-remove-duplicates-equal
  (implies (not (disjoint-p index (remove-duplicates-equal a)))
           (not (disjoint-p index a)))
  :hints (("Goal" :in-theory (e/d* (disjoint-p) ()))))

(defthm not-disjoint-p-of-open-qword-paddr-list-and-remove-duplicates-equal
  (implies (not (disjoint-p index (open-qword-paddr-list (remove-duplicates-equal a))))
           (not (disjoint-p index (open-qword-paddr-list a))))
  :hints (("Goal" :in-theory (e/d* (disjoint-p) ()))))

(defthm no-duplicates-p-member-p-with-append
  (implies (and (no-duplicates-p (append x y))
                (member-p i y))
           (not (member-p i x)))
  :rule-classes (:forward-chaining :rewrite))

(defthm member-p-and-disjoint-p-with-open-qword-paddr-list
  (implies (and (member-p index a)
                (mult-8-qword-paddr-listp a))
           (equal (disjoint-p (list index)
                              (open-qword-paddr-list a))
                  nil))
  :hints (("Goal" :in-theory (e/d* (member-p disjoint-p)
                                   ()))))

(defthm member-p-and-disjoint-p-with-open-qword-paddr-list-and-addr-range
  (implies (and (member-p index a)
                (mult-8-qword-paddr-listp a))
           (equal (disjoint-p (addr-range 8 index)
                              (open-qword-paddr-list a))
                  nil))
  :hints (("Goal" :in-theory (e/d* (member-p disjoint-p)
                                   ()))))

(define gather-all-paging-structure-qword-addresses (x86)

  :parents (gather-paging-structures)

  :short "Returns a list of qword addresses of all the active paging
  structures"

  :guard (not (xr :programmer-level-mode 0 x86))

  :returns (list-of-addresses qword-paddr-listp)

  (b* ( ;; One Page Map Level-4 (PML4) Table:
       (pml4-table-qword-addresses
        (gather-pml4-table-qword-addresses x86))
       ;; Up to 512 Page Directory Pointer Tables (PDPT):
       (pdpt-table-qword-addresses
        (gather-qword-addresses-corresponding-to-entries
         pml4-table-qword-addresses x86))
       ;; Up to 512*512 Page Directories (PD):
       (pd-qword-addresses
        (gather-qword-addresses-corresponding-to-entries
         pdpt-table-qword-addresses x86))
       ;; Up to 512*512*512 Page Tables (PT):
       (pt-qword-addresses
        (gather-qword-addresses-corresponding-to-entries
         pd-qword-addresses x86)))

    (remove-duplicates-equal
     (append
      ;; Each item below is a qword-paddr-listp.
      pml4-table-qword-addresses
      pdpt-table-qword-addresses
      pd-qword-addresses
      pt-qword-addresses)))
  ///
  (std::more-returns (list-of-addresses true-listp))

  (defthm mult-8-qword-paddr-listp-gather-all-paging-structure-qword-addresses
    (mult-8-qword-paddr-listp (gather-all-paging-structure-qword-addresses x86)))

  (defthm no-duplicates-p-gather-all-paging-structure-qword-addresses
    (no-duplicates-p (gather-all-paging-structure-qword-addresses x86))
    :hints (("Goal" :in-theory (e/d* (no-duplicates-p-to-no-duplicatesp-equal)
                                     (no-duplicates-p)))))

  (defthm gather-all-paging-structure-qword-addresses-xw-fld!=mem-and-ctr
    (implies (and (not (equal fld :mem))
                  (not (equal fld :ctr))
                  (not (equal fld :programmer-level-mode)))
             (equal (gather-all-paging-structure-qword-addresses
                     (xw fld index val x86))
                    (gather-all-paging-structure-qword-addresses x86))))

  (defthm gather-all-paging-structure-qword-addresses-xw-fld=ctr
    (implies (not (equal index *cr3*))
             (equal (gather-all-paging-structure-qword-addresses
                     (xw :ctr index val x86))
                    (gather-all-paging-structure-qword-addresses x86))))

  (local
   (defthm gather-all-paging-structure-qword-addresses-xw-fld=mem-disjoint-helper
     (implies (not (member-p index (open-qword-paddr-list (remove-duplicates-equal (append a b c d)))))
              (and (not (member-p index (open-qword-paddr-list a)))
                   (not (member-p index (open-qword-paddr-list b)))
                   (not (member-p index (open-qword-paddr-list c)))
                   (not (member-p index (open-qword-paddr-list d)))))
     :hints (("Goal" :in-theory (e/d* () (not-member-p-of-open-qword-paddr-list-and-remove-duplicates-equal))
              :use ((:instance not-member-p-of-open-qword-paddr-list-and-remove-duplicates-equal
                               (a (append a b c d))))))))

  (defthm gather-all-paging-structure-qword-addresses-xw-fld=mem-disjoint
    (implies (and (not (member-p index
                                 (open-qword-paddr-list
                                  (gather-all-paging-structure-qword-addresses x86))))
                  (physical-address-p index))
             (equal (gather-all-paging-structure-qword-addresses (xw :mem index val x86))
                    (gather-all-paging-structure-qword-addresses x86))))

  (local
   (defthm gather-all-paging-structure-qword-addresses-wm-low-64-disjoint-helper
     (implies (and (disjoint-p index (open-qword-paddr-list (remove-duplicates-equal (append a b c d))))
                   (true-listp d))
              (and (disjoint-p index (open-qword-paddr-list a))
                   (disjoint-p index (open-qword-paddr-list b))
                   (disjoint-p index (open-qword-paddr-list c))
                   (disjoint-p index (open-qword-paddr-list d))))
     :hints (("Goal" :in-theory (e/d* () (disjoint-p-of-open-qword-paddr-list-and-remove-duplicates-equal))
              :use ((:instance disjoint-p-of-open-qword-paddr-list-and-remove-duplicates-equal
                               (a (append a b c d))))))))

  (defthm gather-all-paging-structure-qword-addresses-wm-low-64-disjoint
    (implies (and (disjoint-p (addr-range 8 index)
                              (open-qword-paddr-list
                               (gather-all-paging-structure-qword-addresses x86)))
                  (physical-address-p index))
             (equal (gather-all-paging-structure-qword-addresses
                     (wm-low-64 index val x86))
                    (gather-all-paging-structure-qword-addresses x86))))

  (local
   (defthm gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr-helper
     (implies (and (member-p index (remove-duplicates-equal (append a b c d)))
                   (mult-8-qword-paddr-listp a)
                   (mult-8-qword-paddr-listp b)
                   (mult-8-qword-paddr-listp c)
                   (mult-8-qword-paddr-listp d))
              (and
               (not (and (disjoint-p (addr-range 8 index) (open-qword-paddr-list a))
                         (disjoint-p (addr-range 8 index) (open-qword-paddr-list b))
                         (disjoint-p (addr-range 8 index) (open-qword-paddr-list c))
                         (disjoint-p (addr-range 8 index) (open-qword-paddr-list d))))
               (or (member-p index a)
                   (disjoint-p (addr-range 8 index) (open-qword-paddr-list a)))
               (or (member-p index b)
                   (disjoint-p (addr-range 8 index) (open-qword-paddr-list b)))
               (or (member-p index c)
                   (disjoint-p (addr-range 8 index) (open-qword-paddr-list c)))
               (or (member-p index d)
                   (disjoint-p (addr-range 8 index) (open-qword-paddr-list d)))))
     :hints (("Goal"
              :do-not-induct t
              :in-theory (e/d* () (member-p-of-remove-duplicates-equal))
              :use ((:instance member-p-of-remove-duplicates-equal
                               (a (append a b c d))))))
     :rule-classes nil))

  (defthm gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr
    (implies (and (member-p index (gather-all-paging-structure-qword-addresses x86))
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86))
                  (unsigned-byte-p 64 val)
                  (x86p x86)
                  (not (xr :programmer-level-mode 0 x86)))
             (equal (gather-all-paging-structure-qword-addresses
                     (wm-low-64 index val x86))
                    (gather-all-paging-structure-qword-addresses x86)))
    :hints (("Goal" :use
             ((:instance
               gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr-helper
               (index index)
               (a (gather-pml4-table-qword-addresses x86))
               (b (gather-qword-addresses-corresponding-to-entries
                   (gather-pml4-table-qword-addresses x86)
                   x86))
               (c (gather-qword-addresses-corresponding-to-entries
                   (gather-qword-addresses-corresponding-to-entries
                    (gather-pml4-table-qword-addresses x86)
                    x86)
                   x86))
               (d (gather-qword-addresses-corresponding-to-entries
                   (gather-qword-addresses-corresponding-to-entries
                    (gather-qword-addresses-corresponding-to-entries
                     (gather-pml4-table-qword-addresses x86)
                     x86)
                    x86)
                   x86))))))))

;; ======================================================================

;; Compare the paging structures in two x86 states:

(define xlate-equiv-entries-at-qword-addresses
  (list-of-addresses-1 list-of-addresses-2 x86-1 x86-2)
  :parents (xlate-equiv-structures)
  :non-executable t
  :guard (and (qword-paddr-listp list-of-addresses-1)
              (qword-paddr-listp list-of-addresses-2)
              (equal (len list-of-addresses-1)
                     (len list-of-addresses-2))
              (x86p x86-1)
              (x86p x86-2))

  (if (equal (xr :programmer-level-mode 0 x86-1) nil)
      (if (equal (xr :programmer-level-mode 0 x86-2) nil)

          (if (endp list-of-addresses-1)
              t
            (b* ((addr-1 (car list-of-addresses-1))
                 (addr-2 (car list-of-addresses-2))
                 (qword-1 (rm-low-64 addr-1 x86-1))
                 (qword-2 (rm-low-64 addr-2 x86-2))
                 ((when (not (xlate-equiv-entries qword-1 qword-2)))
                  nil))
              (xlate-equiv-entries-at-qword-addresses
               (cdr list-of-addresses-1) (cdr list-of-addresses-2)
               x86-1 x86-2)))

        nil)
    ;; I choose to say the following instead of (equal (xr
    ;; :programmer-level-mode 0 x86-2) t) so that I can prove that
    ;; this function unconditionally returns a boolean, as opposed to
    ;; returning a boolean only if x86-2 is known to satisfy x86p.
    (equal (xr :programmer-level-mode 0 x86-2)
           (xr :programmer-level-mode 0 x86-1)))

  ///

  (defthm booleanp-of-xlate-equiv-entries-at-qword-addresses
    (booleanp (xlate-equiv-entries-at-qword-addresses addrs addrs x y))
    :rule-classes :type-prescription)

  (defthm xlate-equiv-entries-at-qword-addresses-reflexive
    (implies (qword-paddr-listp a)
             (xlate-equiv-entries-at-qword-addresses a a x x)))

  (defthm xlate-equiv-entries-at-qword-addresses-commutative
    (implies (equal (len a) (len b))
             (equal (xlate-equiv-entries-at-qword-addresses a b x y)
                    (xlate-equiv-entries-at-qword-addresses b a y x)))
    :hints (("Goal" :in-theory (e/d* () (force (force))))))

  (defthm xlate-equiv-entries-at-qword-addresses-transitive
    (implies (and (equal (len a) (len b))
                  (equal (len b) (len c))
                  (xlate-equiv-entries-at-qword-addresses a b x y)
                  (xlate-equiv-entries-at-qword-addresses b c y z))
             (xlate-equiv-entries-at-qword-addresses a c x z)))

  (defthm xlate-equiv-entries-at-qword-addresses-with-xw-fld!=mem
    (implies (and (not (equal fld :mem))
                  (not (equal fld :programmer-level-mode)))
             (equal (xlate-equiv-entries-at-qword-addresses
                     addrs-1 addrs-2
                     x86-1
                     (xw fld index val x86-2))
                    (xlate-equiv-entries-at-qword-addresses
                     addrs-1 addrs-2 x86-1 x86-2))))

  (defthm xlate-equiv-entries-at-qword-addresses-implies-xlate-equiv-entries
    (implies (and (xlate-equiv-entries-at-qword-addresses
                   addrs addrs x86-1 x86-2)
                  (member-p index addrs)
                  (not (xr :programmer-level-mode 0 x86-1)))
             (xlate-equiv-entries (rm-low-64 index x86-1)
                                  (rm-low-64 index x86-2)))
    :hints (("Goal" :in-theory (e/d* (member-p)
                                     (xlate-equiv-entries)))))

  (defthm xlate-equiv-entries-at-qword-addresses-with-xw-mem-disjoint
    (implies (and (physical-address-p index)
                  (disjoint-p (list index)
                              (open-qword-paddr-list addrs)))
             (equal (xlate-equiv-entries-at-qword-addresses
                     addrs addrs
                     x86-1
                     (xw :mem index val x86-2))
                    (xlate-equiv-entries-at-qword-addresses
                     addrs addrs
                     x86-1
                     x86-2)))
    :hints (("Goal" :in-theory (e/d* (member-p) (xlate-equiv-entries)))))

  (defthm xlate-equiv-entries-at-qword-addresses-with-wm-low-64-disjoint
    (implies (and (mult-8-qword-paddr-listp addrs)
                  (physical-address-p index)
                  (disjoint-p (addr-range 8 index)
                              (open-qword-paddr-list addrs)))
             (equal (xlate-equiv-entries-at-qword-addresses
                     addrs addrs
                     x86-1
                     (wm-low-64 index val x86-2))
                    (xlate-equiv-entries-at-qword-addresses
                     addrs addrs
                     x86-1
                     x86-2)))
    :hints (("Goal" :in-theory (e/d* (member-p) (xlate-equiv-entries)))))

  (defthm xlate-equiv-entries-at-qword-addresses-with-wm-low-64-entry-addr
    (implies (and (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (member-p index addrs)
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86-1))
                  (unsigned-byte-p 64 val)
                  (xlate-equiv-entries-at-qword-addresses addrs addrs x86-1 x86-2))
             (xlate-equiv-entries-at-qword-addresses
              addrs addrs
              x86-1
              (wm-low-64 index val x86-2)))
    :hints (("Goal" :in-theory (e/d* (member-p)
                                     (xlate-equiv-entries)))))

  (local
   (defthmd xlate-equiv-entries-at-qword-addresses-with-wm-low-64-different-x86-helper-1
     (implies
      (and (xlate-equiv-entries (rm-low-64 (car addrs) x86-1)
                                (rm-low-64 (car addrs) x86-2))
           (unsigned-byte-p 52 index)
           (unsigned-byte-p 52 (car addrs))
           (equal (loghead 3 (car addrs)) 0)
           (mult-8-qword-paddr-listp (cdr addrs))
           (not (member-p (car addrs) (cdr addrs)))
           (no-duplicates-p (cdr addrs))
           (member-p index (cdr addrs))
           (not (xlate-equiv-entries (rm-low-64 (car addrs) x86-1)
                                     (rm-low-64 (car addrs)
                                                (wm-low-64 index val x86-2)))))
      (not (xlate-equiv-entries-at-qword-addresses (cdr addrs)
                                                   (cdr addrs)
                                                   x86-1 x86-2)))
     :hints (("Goal" :in-theory (e/d* () (mult-8-qword-paddr-listp-and-disjoint-p))
              :use ((:instance mult-8-qword-paddr-listp-and-disjoint-p
                               (index index)
                               (addrs (cdr addrs))
                               (addr (car addrs))))))))

  (local
   (defthmd xlate-equiv-entries-at-qword-addresses-with-wm-low-64-different-x86-helper-2
     (implies (and (not (xlate-equiv-entries (rm-low-64 (car addrs) x86-1)
                                             (rm-low-64 (car addrs) x86-2)))
                   (unsigned-byte-p 52 index)
                   (unsigned-byte-p 52 (car addrs))
                   (equal (loghead 3 (car addrs)) 0)
                   (mult-8-qword-paddr-listp (cdr addrs))
                   (not (member-p (car addrs) (cdr addrs)))
                   (no-duplicates-p (cdr addrs))
                   (member-p index (cdr addrs))
                   (xlate-equiv-entries (rm-low-64 (car addrs) x86-1)
                                        (rm-low-64 (car addrs)
                                                   (wm-low-64 index val x86-2))))
              (not (xlate-equiv-entries-at-qword-addresses
                    (cdr addrs)
                    (cdr addrs)
                    x86-1 (wm-low-64 index val x86-2))))
     :hints (("Goal" :in-theory (e/d* () (mult-8-qword-paddr-listp-and-disjoint-p))
              :use ((:instance mult-8-qword-paddr-listp-and-disjoint-p
                               (index index)
                               (addrs (cdr addrs))
                               (addr (car addrs))))))))

  (defthmd xlate-equiv-entries-at-qword-addresses-with-wm-low-64-different-x86
    (implies (and (mult-8-qword-paddr-listp addrs)
                  (no-duplicates-p addrs)
                  (member-p index addrs)
                  (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86-2))
                  (unsigned-byte-p 64 val))
             (equal
              (xlate-equiv-entries-at-qword-addresses
               addrs addrs
               x86-1
               (wm-low-64 index val x86-2))
              (xlate-equiv-entries-at-qword-addresses addrs addrs x86-1 x86-2)))
    :hints (("Goal"
             :use ((:instance member-p-and-mult-8-qword-paddr-listp))
             :in-theory (e/d* (member-p
                               xlate-equiv-entries-at-qword-addresses)
                              (xlate-equiv-entries)))
            ;; Ugh, subgoal hints.
            ("Subgoal *1/3" :use
             ((:instance xlate-equiv-entries-at-qword-addresses-with-wm-low-64-different-x86-helper-1)))
            ("Subgoal *1/2" :use
             ((:instance xlate-equiv-entries-at-qword-addresses-with-wm-low-64-different-x86-helper-2))))))

;; ======================================================================

;; Defining xlate-equiv-structures:

;; First, some bind-free and other misc. stuff:

(defun find-xlate-equiv-structures-from-occurrence
  (bound-x86-term mfc state)
  (declare (xargs :stobjs (state) :mode :program)
           (ignorable state))
  (b* ((call (acl2::find-call-lst 'xlate-equiv-structures (acl2::mfc-clause mfc)))
       ((when (not call))
        ;; xlate-equiv-structures term not encountered.
        nil)
       (x86-1-var (second call))
       (x86-2-var (third call))

       (x86-var
        (if (equal bound-x86-term x86-1-var)
            x86-2-var
          x86-1-var)))
    x86-var))

(defun find-an-xlate-equiv-x86-aux (thm-name x86-term mfc state)
  (declare (xargs :stobjs (state) :mode :program)
           (ignorable state))

  ;; Finds a "smaller" x86 that is xlate-equiv to x86-term.
  (if (atom x86-term)

      (b* ((equiv-x86-term
            (find-xlate-equiv-structures-from-occurrence
             x86-term ;; bound-x86-term
             mfc state))
           ((when (not equiv-x86-term))
            x86-term))
        equiv-x86-term)

    (b* ((outer-fn (car x86-term))
         ((when (and (not (equal outer-fn 'MV-NTH))
                     (not (equal outer-fn 'WM-LOW-64))
                     (not (and (equal outer-fn 'XW)
                               (equal (second x86-term) '':MEM)))))
          (cw "~%~p0: Unexpected x86-term encountered:~p1~%" thm-name x86-term)
          x86-term))
      (cond ((equal outer-fn 'MV-NTH)
             ;; We expect x86-term to be a function related to page
             ;; traversals.
             (b* ((mv-nth-index (second x86-term))
                  (inner-fn-call (third x86-term))
                  (inner-fn (first inner-fn-call))
                  ((when (if (equal mv-nth-index ''2)
                             (not (member-p inner-fn
                                            '(IA32E-LA-TO-PA-PT
                                              IA32E-LA-TO-PA-PD
                                              IA32E-LA-TO-PA-PDPT
                                              IA32E-LA-TO-PA-PML4T
                                              IA32E-TRANSLATE-LA-TO-PA
                                              PAGING-ENTRY-NO-PAGE-FAULT-P$INLINE
                                              RM08
                                              RB
                                              RB-1
                                              GET-PREFIXES)))
                           (if (equal mv-nth-index ''1)
                               (not (member-p inner-fn '(WM08 WB)))
                             t)))
                   (cw "~%~p0: Unexpected mv-nth x86-term encountered:~p1~%" thm-name x86-term)
                   x86-term)
                  (sub-x86
                   (if (or (equal inner-fn 'RB-1)
                           (equal inner-fn 'PAGING-ENTRY-NO-PAGE-FAULT-P$INLINE))
                       ;; x86 is the next to last argument for these functions.
                       (first (last (butlast inner-fn-call 1)))
                     (first (last inner-fn-call)))))
               sub-x86))
            ((or (equal outer-fn 'WM-LOW-64)
                 (equal outer-fn 'XW))
             ;; We expect x86-term to be of the form (wm-low-64 index
             ;; val sub-x86) or (xw :mem val index).
             (b* ((sub-x86 (first (last x86-term))))
               sub-x86))))))

(defun find-an-xlate-equiv-x86 (thm-name bound-x86-term free-x86-var mfc state)
  (declare (xargs :stobjs (state) :mode :program)
           (ignorable state))
  ;; bind-free for an x86 in xlate-equiv-structures: should check just
  ;; for the page traversal functions and wm-low-64.

  ;; TO-DO: Logic mode...
  (declare (xargs :mode :program))
  (b* ((equiv-x86 (find-an-xlate-equiv-x86-aux thm-name bound-x86-term mfc state)))
    `((,free-x86-var . ,equiv-x86))))

(defun find-equiv-x86-for-components-aux (var calls)
  (if (endp calls)
      nil
    (b* ((call (car calls))
         (var-val (third call)))
      (append `((,var . ,var-val))
              (find-equiv-x86-for-components-aux var (cdr calls))))))

(defun find-equiv-x86-for-components (var mfc state)
  (declare (xargs :stobjs (state) :mode :program)
           (ignorable state))
  (b* ((calls (acl2::find-calls-of-fns-lst
               '(ALL-MEM-EXCEPT-PAGING-STRUCTURES-EQUAL)
               (acl2::mfc-clause mfc))))
    (find-equiv-x86-for-components-aux var calls)))

(define all-mem-except-paging-structures-equal
  (x86-1 x86-2)
  :guard (and (x86p x86-1)
              (x86p x86-2))
  :non-executable t

  :prepwork
  ((define all-mem-except-paging-structures-equal-aux
     (i paging-qword-addresses x86-1 x86-2)
     :parents (all-mem-except-paging-structures-equal)
     :guard (and (natp i)
                 (<= i *mem-size-in-bytes*)
                 (mult-8-qword-paddr-listp paging-qword-addresses)
                 (x86p x86-1)
                 (x86p x86-2))
     :non-executable t
     :enabled t

     (if (zp i)

         (if (disjoint-p
              (list i)
              (open-qword-paddr-list paging-qword-addresses))
             ;; i does not point to paging data, hence the contents of i
             ;; must be exactly equal.

             (equal (xr :mem i x86-1) (xr :mem i x86-2))

           t)

       (if (disjoint-p
            (list (1- i))
            (open-qword-paddr-list paging-qword-addresses))

           ;; i does not point to paging data, hence the contents of i
           ;; must be exactly equal.
           (and (equal (xr :mem (1- i) x86-1) (xr :mem (1- i) x86-2))
                (all-mem-except-paging-structures-equal-aux
                 (1- i) paging-qword-addresses x86-1 x86-2))

         ;; i points to paging data, and hence we can't expect its
         ;; contents to be exactly equal. This case is dealt with by the
         ;; function xlate-equiv-entries-at-qword-addresses?.
         (all-mem-except-paging-structures-equal-aux
          (1- i) paging-qword-addresses x86-1 x86-2)))

     ///

     (defthm all-mem-except-paging-structures-equal-aux-and-xr-mem-from-rest-of-memory
       (implies (and (all-mem-except-paging-structures-equal-aux i addrs x86-1 x86-2)
                     (disjoint-p (list j) (open-qword-paddr-list addrs))
                     (natp i)
                     (natp j)
                     (< j i))
                (equal (xr :mem j x86-1) (xr :mem j x86-2))))

     (defthm all-mem-except-paging-structures-equal-aux-and-rm-low-32-from-rest-of-memory
       (implies (and (all-mem-except-paging-structures-equal-aux i addrs x86-1 x86-2)
                     (disjoint-p (addr-range 4 j) (open-qword-paddr-list addrs))
                     (natp i)
                     (natp j)
                     (< (+ 3 j) i)
                     (not (programmer-level-mode x86-1))
                     (not (programmer-level-mode x86-2)))
                (equal (rm-low-32 j x86-1) (rm-low-32 j x86-2)))
       :hints (("Goal"
                :do-not-induct t
                :in-theory (e/d* (rm-low-32 disjoint-p) (force (force))))))

     (defthm all-mem-except-paging-structures-equal-aux-and-rm-low-64-from-rest-of-memory
       (implies (and (all-mem-except-paging-structures-equal-aux i addrs x86-1 x86-2)
                     (disjoint-p (addr-range 8 j) (open-qword-paddr-list addrs))
                     (natp i)
                     (natp j)
                     (< (+ 7 j) i)
                     (not (programmer-level-mode x86-1))
                     (not (programmer-level-mode x86-2)))
                (equal (rm-low-64 j x86-1) (rm-low-64 j x86-2)))
       :hints (("Goal"
                :do-not-induct t
                :in-theory (e/d* (rm-low-64 disjoint-p) (force (force))))))

     (defthm all-mem-except-paging-structures-equal-aux-is-reflexive
       (all-mem-except-paging-structures-equal-aux i addrs x x))

     (defthm all-mem-except-paging-structures-equal-aux-is-commutative
       (implies (all-mem-except-paging-structures-equal-aux i addrs x y)
                (all-mem-except-paging-structures-equal-aux i addrs y x)))

     (defthm all-mem-except-paging-structures-equal-aux-is-transitive
       (implies (and (all-mem-except-paging-structures-equal-aux i addrs x y)
                     (all-mem-except-paging-structures-equal-aux i addrs y z))
                (all-mem-except-paging-structures-equal-aux i addrs x z)))

     (defthm all-mem-except-paging-structures-equal-aux-and-xw-1
       (implies (not (equal fld :mem))
                (equal (all-mem-except-paging-structures-equal-aux i addrs (xw fld index val x) y)
                       (all-mem-except-paging-structures-equal-aux i addrs x y))))

     (defthm all-mem-except-paging-structures-equal-aux-and-xw-2
       (implies (not (equal fld :mem))
                (equal (all-mem-except-paging-structures-equal-aux i addrs x (xw fld index val y))
                       (all-mem-except-paging-structures-equal-aux i addrs x y))))

     (defthm all-mem-except-paging-structures-equal-aux-and-xw-mem
       (implies (all-mem-except-paging-structures-equal-aux i addrs x y)
                (all-mem-except-paging-structures-equal-aux
                 i addrs
                 (xw :mem index val x)
                 (xw :mem index val y))))

     (defthm xr-mem-wm-low-64
       (implies (and ;; (disjoint-p (list index) (addr-range 8 addr))
                 (not (member-p index (addr-range 8 addr)))
                 (physical-address-p addr))
                (equal (xr :mem index (wm-low-64 addr val x86))
                       (xr :mem index x86)))
       :hints (("Goal" :in-theory (e/d* (wm-low-64
                                         wm-low-32
                                         ifix)
                                        (force (force))))))

     (local
      (defthm all-mem-except-paging-structures-equal-aux-and-wm-low-64-paging-entry-helper
        (implies (and (member-p index a)
                      (mult-8-qword-paddr-listp a)
                      (disjoint-p (list i) (open-qword-paddr-list a)))
                 (equal (member-p i (addr-range 8 index))
                        nil))
        :hints (("Goal" :in-theory (e/d* (member-p disjoint-p)
                                         ())))))

     (defthm all-mem-except-paging-structures-equal-aux-and-wm-low-64-paging-entry
       (implies (and (member-p index addrs)
                     (mult-8-qword-paddr-listp addrs))
                (equal (all-mem-except-paging-structures-equal-aux i addrs (wm-low-64 index val x) y)
                       (all-mem-except-paging-structures-equal-aux i addrs x y)))
       :hints (("Goal" :in-theory (e/d* (member-p) ()))))

     (defthm all-mem-except-paging-structures-equal-aux-and-wm-low-64
       (implies (and (all-mem-except-paging-structures-equal-aux i addrs x y)
                     (not (xr :programmer-level-mode 0 x))
                     (not (xr :programmer-level-mode 0 y)))
                (all-mem-except-paging-structures-equal-aux
                 i addrs
                 (wm-low-64 index val x)
                 (wm-low-64 index val y)))
       :hints (("Goal" :do-not-induct t
                :in-theory (e/d* (wm-low-64 wm-low-32) ()))))

     (defthm all-mem-except-paging-structures-equal-aux-and-xw-mem-commute-writes
       (implies (not (equal index-1 index-2))
                (all-mem-except-paging-structures-equal-aux
                 i addrs
                 (xw :mem index-1 val-1 (xw :mem index-2 val-2 x))
                 (xw :mem index-2 val-2 (xw :mem index-1 val-1 x)))))))

  (if (equal (programmer-level-mode x86-1) nil)

      (if (equal (programmer-level-mode x86-2) nil)

          (and (equal (gather-all-paging-structure-qword-addresses x86-1)
                      (gather-all-paging-structure-qword-addresses x86-2))
               (all-mem-except-paging-structures-equal-aux
                *mem-size-in-bytes*
                (gather-all-paging-structure-qword-addresses x86-1)
                x86-1 x86-2))

        nil)

    (equal (programmer-level-mode x86-2) (programmer-level-mode x86-1)))

  ///

  (defequiv all-mem-except-paging-structures-equal)

  (defthm all-mem-except-paging-structures-equal-and-xr-mem-from-rest-of-memory
    (implies (and (all-mem-except-paging-structures-equal x86-1 x86-2)
                  (disjoint-p
                   (list j)
                   (open-qword-paddr-list (gather-all-paging-structure-qword-addresses x86-1)))
                  (natp j)
                  (< j *mem-size-in-bytes*)
                  (not (programmer-level-mode x86-1)))
             (equal (xr :mem j x86-1) (xr :mem j x86-2)))
    :hints (("Goal" :in-theory (e/d* (all-mem-except-paging-structures-equal) ()))))

  (defthm all-mem-except-paging-structures-equal-and-rm-low-64-from-rest-of-memory
    (implies (and (all-mem-except-paging-structures-equal x86-1 x86-2)
                  (disjoint-p (addr-range 8 j)
                              (open-qword-paddr-list
                               (gather-all-paging-structure-qword-addresses x86-1)))
                  (natp j)
                  (< (+ 7 j) *mem-size-in-bytes*))
             (equal (rm-low-64 j x86-1) (rm-low-64 j x86-2)))
    :hints (("Goal"
             :use ((:instance all-mem-except-paging-structures-equal-aux-and-rm-low-64-from-rest-of-memory
                              (i *mem-size-in-bytes*)
                              (j j)
                              (addrs (gather-all-paging-structure-qword-addresses x86-1))))
             :in-theory (e/d* (all-mem-except-paging-structures-equal)
                              (all-mem-except-paging-structures-equal-aux-and-rm-low-64-from-rest-of-memory)))))

  (defthm all-mem-except-paging-structures-equal-and-xw-1
    (implies (and (not (equal fld :mem))
                  (not (equal fld :ctr))
                  (not (equal fld :programmer-level-mode)))
             (equal (all-mem-except-paging-structures-equal (xw fld index val x) y)
                    (all-mem-except-paging-structures-equal (double-rewrite x) y)))
    :hints (("Goal" :in-theory (e/d* () (all-mem-except-paging-structures-equal-aux)))))

  (defthm all-mem-except-paging-structures-equal-and-xw-2
    (implies (and (not (equal fld :mem))
                  (not (equal fld :ctr))
                  (not (equal fld :programmer-level-mode)))
             (equal (all-mem-except-paging-structures-equal x (xw fld index val y))
                    (all-mem-except-paging-structures-equal x (double-rewrite y)))))

  (defthm all-mem-except-paging-structures-equal-and-xw
    (implies (and (not (equal fld :mem))
                  (not (equal fld :ctr))
                  (not (equal fld :programmer-level-mode)))
             (equal (all-mem-except-paging-structures-equal (xw fld index val x) (xw fld index val y))
                    (all-mem-except-paging-structures-equal x y))))

  (defthm all-mem-except-paging-structures-equal-and-xw-mem-except-paging-structure
    (implies (and (bind-free (find-equiv-x86-for-components y mfc state))
                  (all-mem-except-paging-structures-equal x y)
                  (physical-address-p index)
                  (disjoint-p
                   (list index)
                   (open-qword-paddr-list (gather-all-paging-structure-qword-addresses y))))
             (all-mem-except-paging-structures-equal (xw :mem index val x)
                                                     (xw :mem index val y)))
    :hints (("Goal" :in-theory (e/d* () (force (force))))))

  (defthm all-mem-except-paging-structures-equal-and-wm-low-64-paging-entry
    (implies (and (member-p index (gather-all-paging-structure-qword-addresses x))
                  (equal (gather-all-paging-structure-qword-addresses (wm-low-64 index val x))
                         (gather-all-paging-structure-qword-addresses x)))
             (equal (all-mem-except-paging-structures-equal (wm-low-64 index val x) y)
                    (all-mem-except-paging-structures-equal (double-rewrite x) y)))
    :hints (("Goal" :in-theory (e/d* () (all-mem-except-paging-structures-equal-aux)))))

  (defthm all-mem-except-paging-structures-equal-and-wm-low-64-entry-addr
    (implies (and (xlate-equiv-entries (double-rewrite entry)
                                       (rm-low-64 entry-addr x86))
                  (member-p entry-addr (gather-all-paging-structure-qword-addresses x86))
                  (x86p (double-rewrite x86))
                  (unsigned-byte-p 64 entry))
             (all-mem-except-paging-structures-equal
              (wm-low-64 entry-addr entry x86)
              (double-rewrite x86)))
    :hints (("Goal" :in-theory (e/d* (all-mem-except-paging-structures-equal-aux)
                                     ()))))

  (defthm all-mem-except-paging-structures-equal-and-wm-low-64-except-paging-structure
    (implies (and
              (bind-free (find-equiv-x86-for-components y mfc state))
              (all-mem-except-paging-structures-equal x y)
              (physical-address-p index)
              (disjoint-p
               (addr-range 8 index)
               (open-qword-paddr-list (gather-all-paging-structure-qword-addresses y))))
             (all-mem-except-paging-structures-equal (wm-low-64 index val x)
                                                     (wm-low-64 index val y)))
    :hints (("Goal" :in-theory (e/d* () (force (force))))))

  (defthm all-mem-except-paging-structures-equal-and-xw-mem-commute-writes
    (implies (not (equal index-1 index-2))
             (all-mem-except-paging-structures-equal
              (xw :mem index-1 val-1 (xw :mem index-2 val-2 x))
              (xw :mem index-2 val-2 (xw :mem index-1 val-1 x))))
    :hints (("Goal" :in-theory (e/d* () (force (force)))))))

(define xlate-equiv-structures (x86-1 x86-2)
  :guard (and (x86p x86-1)
              (x86p x86-2))
  :non-executable t
  :long "<p>Two x86 states are @('xlate-equiv-structures') if their
  paging structures are equal, modulo the accessed and dirty bits (See
  @(see xlate-equiv-entries)).</p>"

  (if (equal (xr :programmer-level-mode 0 x86-1) nil)

      (if (equal (xr :programmer-level-mode 0 x86-2) nil)

          (let* ((paging-qword-addresses-1
                  (gather-all-paging-structure-qword-addresses x86-1))
                 (paging-qword-addresses-2
                  (gather-all-paging-structure-qword-addresses x86-2)))

            (and (equal (seg-sel-layout-slice :rpl (seg-visiblei *cs* x86-1))
                        (seg-sel-layout-slice :rpl (seg-visiblei *cs* x86-2)))
                 (equal (cr0-slice :cr0-wp (n32 (ctri *cr0* x86-1)))
                        (cr0-slice :cr0-wp (n32 (ctri *cr0* x86-2))))
                 (equal (cr3-slice :cr3-pdb (ctri *cr3* x86-1))
                        (cr3-slice :cr3-pdb (ctri *cr3* x86-2)))
                 (equal (cr4-slice :cr4-smep (loghead 22 (ctri *cr4* x86-1)))
                        (cr4-slice :cr4-smep (loghead 22 (ctri *cr4* x86-2))))
                 (equal (cr4-slice :cr4-smap (loghead 22 (ctri *cr4* x86-1)))
                        (cr4-slice :cr4-smap (loghead 22 (ctri *cr4* x86-2))))
                 (equal (ia32_efer-slice :ia32_efer-nxe (n12 (msri *ia32_efer-idx* x86-1)))
                        (ia32_efer-slice :ia32_efer-nxe (n12 (msri *ia32_efer-idx* x86-2))))
                 (equal (rflags-slice :ac (rflags x86-1))
                        (rflags-slice :ac (rflags x86-2)))
                 (equal paging-qword-addresses-1 paging-qword-addresses-2)
                 (xlate-equiv-entries-at-qword-addresses
                  paging-qword-addresses-1 paging-qword-addresses-2 x86-1 x86-2)))

        nil)

    (equal (xr :programmer-level-mode 0 x86-2)
           (xr :programmer-level-mode 0 x86-1)))

  ///

  (local
   (defthm xlate-equiv-structures-is-reflexive
     (xlate-equiv-structures x x)
     :hints (("Goal"
              :in-theory (e/d* () (xlate-equiv-entries-at-qword-addresses-reflexive))
              :use
              ((:instance
                xlate-equiv-entries-at-qword-addresses-reflexive
                (a (gather-all-paging-structure-qword-addresses x))
                (x x)))))))

  (local
   (defthm xlate-equiv-structures-is-commutative
     (implies (xlate-equiv-structures x y)
              (xlate-equiv-structures y x))
     :hints (("Goal"
              :in-theory (e/d* () (xlate-equiv-entries-at-qword-addresses-commutative))
              :use
              ((:instance
                xlate-equiv-entries-at-qword-addresses-commutative
                (a (gather-all-paging-structure-qword-addresses x))
                (b (gather-all-paging-structure-qword-addresses y))
                (x x)
                (y y)))))))

  (local
   (defthm xlate-equiv-structures-is-transitive
     (implies (and (xlate-equiv-structures x y)
                   (xlate-equiv-structures y z))
              (xlate-equiv-structures x z))
     :hints (("Goal"
              :in-theory (e/d* () (xlate-equiv-entries-at-qword-addresses-transitive))
              :use
              ((:instance
                xlate-equiv-entries-at-qword-addresses-transitive
                (a (gather-all-paging-structure-qword-addresses x))
                (b (gather-all-paging-structure-qword-addresses y))
                (c (gather-all-paging-structure-qword-addresses z))))))))

  (defequiv xlate-equiv-structures
    :hints (("Goal" :in-theory (e/d* () (xlate-equiv-structures)))))

  (defthm xlate-equiv-structures-and-xw
    (implies (and (not (equal fld :mem))
                  (not (equal fld :seg-visible))
                  (not (equal fld :msr))
                  (not (equal fld :ctr))
                  (not (equal fld :rflags))
                  (not (equal fld :programmer-level-mode)))
             (xlate-equiv-structures (xw fld index val x86)
                                     (double-rewrite x86))))

  (defthm xlate-equiv-structures-and-programmer-level-mode
    (implies (xlate-equiv-structures x86-1 x86-2)
             (equal (xr :programmer-level-mode 0 x86-1)
                    (xr :programmer-level-mode 0 x86-2)))
    :rule-classes :congruence))

;; =====================================================================

;; gather-all-paging-structure-qword-addresses and wm-low-64, with
;; equiv x86s:

(defthm gather-all-paging-structure-qword-addresses-wm-low-64-different-x86-disjoint
  (implies (and (bind-free
                 (find-an-xlate-equiv-x86
                  'gather-all-paging-structure-qword-addresses-wm-low-64-different-x86-disjoint
                  x86-1 'x86-2 mfc state)
                 (x86-2))
                (xlate-equiv-structures (double-rewrite x86-1) (double-rewrite x86-2))
                (not (programmer-level-mode (double-rewrite x86-1)))
                (disjoint-p
                 (addr-range 8 index)
                 (open-qword-paddr-list (gather-all-paging-structure-qword-addresses x86-1)))
                (physical-address-p index))
           (equal (gather-all-paging-structure-qword-addresses
                   (wm-low-64 index val x86-1))
                  (gather-all-paging-structure-qword-addresses x86-2)))
  :hints (("Goal"
           :use ((:instance gather-all-paging-structure-qword-addresses-wm-low-64-disjoint
                            (x86 x86-1)))
           :in-theory (e/d* (xlate-equiv-structures)
                            (pairwise-disjoint-p-aux
                             open-qword-paddr-list
                             gather-all-paging-structure-qword-addresses-wm-low-64-disjoint
                             gather-all-paging-structure-qword-addresses)))))

(defthm gather-all-paging-structure-qword-addresses-wm-low-64-different-x86
  (implies (and (xlate-equiv-structures x86 (double-rewrite x86-equiv))
                (not (programmer-level-mode x86))
                (x86p x86-equiv)
                (member-p index (gather-all-paging-structure-qword-addresses x86))
                (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86))
                (unsigned-byte-p 64 val))
           (equal (gather-all-paging-structure-qword-addresses
                   (wm-low-64 index val x86-equiv))
                  (gather-all-paging-structure-qword-addresses x86)))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-structures)
                                   (gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr))
           :use ((:instance gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr
                            (x86 x86-equiv))
                 (:instance gather-all-paging-structure-qword-addresses-wm-low-64-entry-addr
                            (x86 x86))))))

;; ======================================================================

;; xlate-equiv-structures and write(s) to physical memory:

(defthm xlate-equiv-structures-and-xw-mem-disjoint
  (implies (and (disjoint-p
                 (list index)
                 (open-qword-paddr-list
                  (gather-all-paging-structure-qword-addresses x86)))
                (physical-address-p index)
                (unsigned-byte-p 8 val)
                (x86p x86))
           (xlate-equiv-structures
            (xw :mem index val x86)
            (double-rewrite x86)))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-structures) ()))))

(defthm xlate-equiv-structures-and-wm-low-64-disjoint
  (implies (and
            (bind-free
             (find-an-xlate-equiv-x86
              'xlate-equiv-structures-and-wm-low-64-disjoint x86-2 'x86-1 mfc state)
             (x86-1))
            (xlate-equiv-structures x86-1 (double-rewrite x86-2))
            (disjoint-p (addr-range 8 index)
                        (open-qword-paddr-list
                         (gather-all-paging-structure-qword-addresses x86-1)))
            (physical-address-p index))
           (xlate-equiv-structures (wm-low-64 index val x86-2) x86-1))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-structures) ()))))

(defthm xlate-equiv-structures-and-wm-low-64-entry-addr
  (implies (and
            (bind-free
             (find-an-xlate-equiv-x86 'xlate-equiv-structures-and-wm-low-64-entry-addr
                                      x86-equiv 'x86 mfc state)
             (x86))
            (xlate-equiv-structures x86 (double-rewrite x86-equiv))
            (xlate-equiv-entries (double-rewrite val) (rm-low-64 index x86))
            (member-p index (gather-all-paging-structure-qword-addresses x86))
            (x86p x86-equiv)
            (unsigned-byte-p 64 val))
           (xlate-equiv-structures (wm-low-64 index val x86-equiv) x86))
  :hints (("Goal"
           :in-theory (e/d* (xlate-equiv-structures) ()))))

;; ======================================================================

;; Some misc. lemmas:

(defthmd xlate-equiv-entries-open
  (implies (and (xlate-equiv-entries e-1 e-2)
                (unsigned-byte-p 64 e-1)
                (unsigned-byte-p 64 e-2))
           (and (equal (loghead 5 e-1) (loghead 5 e-2))
                (equal (logtail 7 e-1) (logtail 7 e-2))))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-entries) ()))))

(defthm xlate-equiv-structures-and-xlate-equiv-entries-at-qword-addresses
  (implies (and (equal addrs (gather-all-paging-structure-qword-addresses x86))
                (not (programmer-level-mode x86))
                (xlate-equiv-structures (double-rewrite x86) (double-rewrite x86-equiv)))
           (xlate-equiv-entries-at-qword-addresses addrs addrs x86 x86-equiv))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-structures xlate-equiv-structures)
                                   ()))))

(defthmd xlate-equiv-structures-and-xlate-equiv-entries
  (implies (and (xlate-equiv-structures x86-1 x86-2)
                (member-p index (gather-all-paging-structure-qword-addresses x86-1))
                (not (programmer-level-mode x86-1)))
           (xlate-equiv-entries (rm-low-64 index x86-1) (rm-low-64 index x86-2)))
  :hints (("Goal" :in-theory (e/d* (xlate-equiv-structures xlate-equiv-structures)
                                   ()))))

;; ======================================================================

; Copyright (C) 2013, Regents of the University of Texas
; Written by Sandip Ray and Matt Kaufmann, October, 2006
; License: A 3-clause BSD license.  See the LICENSE file distributed with ACL2.

(in-package "ACL2")

#|

 defspec.lisp
 ~~~~~~~~~~~~

Authors: Sandip Ray and Matt Kaufmann
Date: Wed Oct 18 01:01:24 2006

[ Caveat: This book is experimental and might undergo some modfications soon. ]

[Incorporates some suggestions and advice by J Strother Moore.]

[ Uninteresting Aside: Parenthesis in many places at the prefatory comments
  have been replaced by square brackets to facilitate syntax highlighting in
  emacs.]

The Problem
-----------

Suppose you have created an encapsulation with a collection of constraints.
The encapsulation might model some system or some policy or some property in an
abstract fashion.  Suppose you then want to refine this model, possibly by
introducing a collection of concrete definitions.  You might then want to
insure that the concrete model is indeed an instance of the abstract one, in
that the concrete definitions satisfy the constraints posited by the abstract
one.  How do you provide a formal answer to this question in ACL2?  Functional
instantiation provides only a partial answer, in that if we had proven a
*property* of the abstract model then we could functionally instantiate this
abstract property to derive the corresponding property for the concrete one.
But there are situations in which we do not have a specific property that we
want to funtionally instantiate, but rather just want to say in some formal way
that "all the abstract constraints are satisfied by the concrete functions".
An example for that might be a security policy implemented by a system.  One
wants to model the security policy in as abstract a manner as possible so that
the security evaluators can check the policy and satisfy themselves that it is
indeed a valid security policy.  Then one might provide a definition of a
concrete system and want to say that the system implements the security policy
specified.  Clearly there is no *theorem* here to be functionally instantiated.
Of course one can prove the concrete versions of the constraints separately and
get done with it.  But a concrete model might be very complicated and given
such a concrete theorem (in contrast with an abstract specification via
encapsulation) it is a substantial effort for an evaluator to realize that it
indeed does implement the security policy desired.  Some formal way of showing
the correspondence is clearly better.

The real problem is that ACL2 is a theorem prover for first order logic, not
higher-order logic, while the statement we want to make is inherently a
higher-order statement.  In higher order logic we could have, for instance,
defined the security policy as a closed form formula parameterized with
[abstract] Functions, and then the notion of a concrete model satisfying the
policy could have been written as an instance of the same formula with the
concrete functions.  But in first-order logic this is not possible.  Although
functional instantiation gives the illusion of higher-order reasoning, it is
after all a derived rule of inference. 

The Approach
-------------

Since the notion "concrete functions implement the abstract ones" is a
higher-order notion, we cannot hope to write that notion as a closed-form
formula in ACL2.  We must therefore be content with "merely" providing an
illusion of this higher-order notion via macros, and proving all the relevant
first-order proof obligations.  The first order obligations, of course, are
just that the concrete versions of the constraints are theorems.  In an
appropriate higher-order logic, these would be sufficient to prove the final
closed-form (higher-order) theorems.  Here we merely simulate the notion of the
closed-form theorem with macros.

Our approach consists of two parts, each supported by a macro.  In the first
part, we introduce the notion of an abstract system satisfying certain
constraints.  This is done by the macro defspec.  The macro defspec expands
into an encapsulate with the appropriate constraining of the function symbols
involved.  It then creates a table event with a table to store the constraints
together with a name.  We think of the name as the higher-order predicate which
has the constrained functions as parameters and the constraints on the
functions specify when this (parametermized) higher-order predicate is true.
The second part is to justify that the instances of the constraints defined for
the abstract model.  We do this by essentially creating the theorem that is
produced by replacing terms composed of application of abstract functions by
their concrete counterparts in the constraints generated by the defspec.  This
macro, which is called definstance, simply uses the built-in ACL2 function for
building functional instance to create the instance of the constraints and
generate a theorem which is then presented to ACL2.  The macro takes the name
of the key the table event introduced by defspec and a functional substitution
to generate this theorem.  We can view this macro as producing essentially an
instance of the higher-order predicate with the concrete versions of the
function parameters.

One might argue that this is nowhere near the closed-form formula that we want
to ideally state, and the author agrees.  After all macros are syntactic sugar.
But having one macro that generates the instances will give the evaluators the
ability to trust it, rather than hand-coded proofs that all the "corresponding"
constraints are satisfied.  The hope is that with a lot of use the macros here
will be conventionally thought of as higher-order representations.  There is
precedence of such.  For instance, ACL2 is a quantifier-free logic, and
defun-sk is just a macro (that is, syntactic sugar).  However, most ACL2 users
who use defun-sk (including the author) tend to think of a predicate introduced
by this macro as a quantified formula.  This argument is not intended to
justify the weakness of the logic, but merely to show that there is
precedent for such conventions and with sufficient use conventions become
practice.

Notes
-----

1.  There is really no need to introduce the table event and defspec, at least
technically.  The macro definstance could have taken a functional substitution
and one of the function names constrained and generated the constraints that
were stored in the table.  I prefer the table only because I can then provide a
name.  The name enables us to think, at least informally, of defspec as a
higher-order function.

2.  Technically, there is no need for the encapsulate.  All that matters is
that we generate the term in the table event.  I generate the encapsulate more
to help the evaluator in checking that the abstract functions do mean
something.  This of course precludes adding constraints as defaxioms.  But I
consider this a good rather than a bad thing, because it provides a consistency
guarantee at the time a defspec is admitted.

3.  There is one little wrinkle in that some include-book event (or something
else) occurring between the defspec and definstance events overwrites the key
in the table.  I can't handle that with a guard on the table event that only
talks about the key.  The work-around, suggested by Matt Kaufmann, is to
introduce a deflabel event with the same name as the key and put the
[non-]existence of deflabel as the table guard.  Since the deflabel event will
be subsequently present, the key cannot be overwritten.

TODOS
-----

[These were raised by Matt Kaufmann in emails dated: Wed, 18 Oct 2006 08:06:03]

1. Address issues due to variable capture.

 [ Relevant part of Matt's email: 
 
 The comment on sublis-fn (in history-management.lisp) says:

  It is assumed that alist will not allow capturing of its free
  variables by lambda expressions in term.

 It goes on to say that a "draconion check" ensures this.  So I wonder
 if you need a similar draconian check. ]

Note on this: 

Kaufmann has extended the built-in system function sublis-fn to incorporate the
check in there [and thereby got rid of the "draconican check" mentioned above.
With the new sublis-fn, we do not need further checks; we can just use
sublis-fn.

2. Add error-checking.

  [ Relevant part of Matt's email: 
    
   I notice that you didn't do any error checking for the
   functional substitution in definstance.  The ACL2 source function
   translate-functional-substitution might be of use here.  Maybe you
   wouldn't then need create-alist-from-func-list, but I haven't thought
   this through. ]

3. Think about implicit constraints.

  [ Relevant part of Matt's email: 
   
  The constraints introduced by an encapsulate aren't necessarily 
  what the user might expect, because definitions of functions not 
  in the signature might or might not contribute to the constraint. ]

|#


;; We first create the table event.  The second conjunct of the guard, together
;; with the fact that defspec generates a deflabel event insures that the key
;; cannot be subsequently overwritten.

(table spec-table nil nil
       :guard
       (and (symbolp key)
            (not (getprop key 'label nil 'current-acl2-world world))))


(defun constraint (fn wrld)
  (declare (xargs :mode :program))
  (mv-let (sym x)
          (constraint-info fn wrld)
          (cond
           ((eq x *unknown-constraints*)
            (er hard 'constraint
                "Unable to determine constraints on ~x0!  Presumably this ~
                 function was introduced with ~
                 define-trusted-clause-processor; see :DOC ~
                 define-trusted-clause-processor."))
           (sym (conjoin x))
           (t x))))

(defmacro defspec (name &rest args)
  `(progn

     ;; First we want to lay down the encapsulate.
     (encapsulate ,@args)

     ;; Then we look at the world via make-event to create the appropriate
     ;; table-event.  Note that we are assuming that the form we are given is
     ;; something that physically looks like an encapsulate, with defspec name
     ;; instead of an encapulate.  We do not, for instance, handle something
     ;; that is a macro but expands into the right form.  The reason is that I
     ;; do not want to get into the business of macro expansion.  Of course I
     ;; guess I could just have looked at the world, using scan-to-event, to
     ;; figure out the actual event that was just introduced.  But I don't
     ;; bother.
     (make-event
      (let* ((signatures (quote ,(first args)))
             (sig (first signatures))

             ;; The reason for the if statement here is that there are two
             ;; flavors of signature, for instance (f (x) t) and ((f *) =>
             ;; *).  I do not do further error-checking here since the
             ;; encapsulate presumably had passed the ACL2 check.  The farg is
             ;; the first function symbol that has been introduced during the
             ;; encapsulation.  I just care about that since the constraints
             ;; are all associated with this function.
             (farg (if (consp (first sig)) 
                       (first (first sig))
                     (first sig)))

             ;; I am collecting the constraint generated from the
             ;; encapsulation, which can be thought of as the formula
             ;; representing the higher-order notion of formula parameterized
             ;; by the functions in the signature.
             (val-term (constraint farg (w state)))

             (name (quote ,name)))
        
        ;; Now generate the final event.

        `(progn 
           (table spec-table (quote ,name) (quote ,val-term))
           
           ;; I generated the table event but I want to insure that this entry
           ;; will remain in this table.  I do so by now geneating a deflabel
           ;; with the key.  Notice that the table-guard for the table says
           ;; that the key is not one of the labels, which guarantees that
           ;; other people in some include-book for instance cannot overwrite
           ;; this entry.

           (deflabel ,name))))))


;; This function is not necessary.  I write it just so that I can write a
;; functional substitution as a list ((f0 g0) (f1 g1)) rather than ((f0 . g0)
;; (f1. g1)).   Nothing more than aesthetics here.

(defun create-alist-from-func-list (lst)
  (if (endp lst) nil
    (acons (first (first lst))
           (second (first lst))
           (create-alist-from-func-list (rest lst)))))

;; Now we write the macro definstance to instantiate the abstract functions
;; introduced via defspec to the concrete functions.  To do so I create a
;; functional substitution of the constraints and then prove that as a
;; theorem.  The functional substitution is implemented with the same functions
;; that are used to compute substitution for functional instance in ACL2.

(defmacro definstance 
  (spec-name thm-name 
             &key 
             (functional-substitution 'nil)
             instructions hints otf-flg rule-classes doc)
  `(make-event 
    (mv-let 

     ;; I should really start using er-let*.  I like the mv-let form since it
     ;; makes the arguments explicit.
     (erp term state)

     ;; So I get the constraint term from the table.
     (table spec-table (quote ,spec-name))

     (assert$
      (null erp)
      (let* 
          (
           ;; First create the alist as necessary for this function.  Going from
           ;; aesthetic to practical.

           (substitution 
            (create-alist-from-func-list (quote ,functional-substitution)))

           ;; Use the theorem name for creating the defthm.
           (thm-name (quote ,thm-name))

           ;; The rest of the keywords are all arguments to defthm.

           (hints (quote ,hints))
           (instructions (quote ,instructions))
           (doc ,doc)
           (rule-classes ,rule-classes)
           (otf-flg ,otf-flg)
        
           ;; Here is where I create the appropriate form.
           (thm-form 
            (mv-let (erp thm)
                    (sublis-fn substitution term nil)
                    (declare (ignore erp))
                    thm)))
        (value 

         ;; And finally I lay out the defthm event.  Notice that the default is
         ;; rule-classes nil, and the reason is that I didn't see the
         ;; constraints as particularly good rewrite rules in the first place.

         `(defthm ,thm-name 
            ,thm-form
            :hints ,hints
            :instructions ,instructions
            :doc ,doc
            :rule-classes ,rule-classes
            :otf-flg ,otf-flg)))))))


;; Now we test the macros.  Since I want to include both success and failure I
;; use the must-succeed and must-fail macros.

(local
 (include-book "misc/eval" :dir :system))

;; All the tests are marked local.  I do it this way rather than in comments
;; since I want to make sure that the tests execute when I certify the book,
;; but I don't want to have them clutter things when I include the books.  I
;; also put the different tests in different encapsulates (with all events
;; local) so that I can do independent testing.

(local
 (must-succeed
  (local
   (encapsulate
    ()
    (local
     (defspec foo 
       (((f *) => *)) 
       (local (defun f (x) x)) 
       (defthm foo-identity (equal (f x) x))))
    
    (local (defun g (x) x))
    
    (local
     (definstance foo g-is-identity
       :functional-substitution
       ((f (lambda (x) (g x))))))))))
 
;; The following succeeds, surprisingly.  Should it fail?  I think the current
;; behavior is actually correct.  Here we introduce an "empty" encapsulate, and
;; then instantiate it with an arbitrary concrete function.  The instantiation
;; succeeds since the empty model is implemented by every definition.


(local
 (must-succeed
  (local
   (encapsulate
    ()
    (local
     (defspec bar () (local (defun f (x) x))))
       
    (local (defun g (x) (cons x x)))
    
    (local
     (definstance bar g-is-arbitrary
       :functional-substitution
       ((f (lambda (x) (g x))))))))))
             

;; This one fails since the constraints don't hold.

(local
 (must-fail ; See note about ld-skip-proofsp in the definition of must-fail.
  (local
   (encapsulate
    ()
    (local
     (defspec baz
       (((f *) => *)) 
       (local (defun f (x) x)) 
       (defthm f-is-identity (equal (f x) x))))
    
    (local (defun g (x) (cons x x)))
    
    (local
     (definstance baz g-is-identity
       :functional-substitution
       ((f (lambda (x) (g x))))))))))

;; Now we do a sequence of tests to justify the security of the table event
;; with deflabel.  

;; This one fails since we cannot introduce two defspecs with the same h.  The
;; first one lays down a deflabel and the next one cannot succeed because of
;; the presence of the deflabel.

(local
 (must-fail ; See note about ld-skip-proofsp in the definition of must-fail.
  (local
   (encapsulate
    ()
    (local
     (defspec h
       (((f *) => *)) 
       (local (defun f (x) x)) 
       (defthm f-is-identity (equal (f x) x))))

    (local 
     (defspec h 
       (((g *) => *))
       (local (defun g (x) x))
       (defthm g-is-identity (equal (g x) x))))))))

;; Now we try to manually modify the table spec-table.  This fails because of
;; the table-guard.

(local
 (must-fail ; See note about ld-skip-proofsp in the definition of must-fail.
  (local
   (encapsulate
    ()
    (local
     (defspec i
       (((f *) => *)) 
       (local (defun f (x) x)) 
       (defthm f-is-identity (equal (f x) x))))

    (table spec-table 'i 10)))))

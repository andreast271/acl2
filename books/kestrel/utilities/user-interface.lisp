; User Interface
;
; Copyright (C) 2017 Kestrel Institute (http://www.kestrel.edu)
; Copyright (C) 2017 Regents of the University of Texas
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Authors:
;   Alessandro Coglio (coglio@kestrel.edu)
;   Eric Smith (eric.smith@kestrel.edu)
;   Matt Kaufmann (kaufmann@cs.utexas.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "event-forms")
(include-book "maybe-unquote")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection user-interface
  :parents (kestrel-utilities system-utilities)
  :short "Utilities for the user interface of event-generating macros
          (e.g. program transformations).")

(define suppress-output ((form pseudo-event-formp))
  :returns (form-with-output-suppressed pseudo-event-formp)
  :parents (user-interface)
  :short "Wrap an event form with a construct to suppress its output."
  `(with-output
     :gag-mode nil
     :off :all
     :on error
     ,form))

(define maybe-suppress-output (suppress (form pseudo-event-formp))
  :returns (form-with-output-maybe-suppressed pseudo-event-formp :hyp :guard)
  :parents (user-interface)
  :short "Conditionally wrap an event form
          with a construct to suppress its output."
  :long
  "<p>
   If @('suppress') is non-@('nil'),
   wrap the event-form @('form') with a construct to suppress its output.
   Otherwise, just return @('form').
   </p>"
  (if suppress
      (suppress-output form)
    form))

; The following function should probably be completely replaced by
; manage-screen-output, below.  The key difference is that
; control-screen-output will show error output even if it is suppressed
; globally, while manage-screen output respects the case of global suppression
; by avoiding the production of error output.
(define control-screen-output (verbose (form pseudo-event-formp))
  :returns (form-with-output-controlled pseudo-event-formp :hyp :guard)
  :parents (user-interface)
  :short "Control the screen output generated from an event form."
  :long
  "<p>
   If @('verbose') is not @('nil') or @(''nil'), keep all screen output.
   If @('verbose') is @('nil') or @(''nil'), suppress all non-error screen
   output.
   </p>
   <p>
   This function can be used in a macro of the following form:
   @({
     (defmacro mac (... &key verbose ...)
       (control-screen-output verbose `(make-event ...)))
   })
   Invoking @('mac') at the ACL2 top-level will submit the event,
   with the screen output controlled by @('verbose').
   </p>"
  (cond ((maybe-unquote verbose) form)
        (t `(with-output
              :gag-mode nil
              :off :all
              :on error
              ,form))))

; The following function, control-screen-output-and-maybe-replay, is obsolete
; except that it is used in the workshop books' version of simplify-defun,
; books/workshops/2017/coglio-kaufmann-smith/support/simplify-defun.lisp.
(define control-screen-output-and-maybe-replay
  ((verbose "@('t') (or @(''t')) or @('nil') (or @(''nil')), else indicates
             replay on failure.")
   (event-p "Make an event when true.")
   (form (pseudo-event-formp form)))
  :returns (new-form pseudo-event-formp :hyp (pseudo-event-formp form))
  :parents (user-interface)
  :short "Variant of @(tsee control-screen-output)
          that can replay a failure verbosely."
  :long
  "<p>Usage:</p>

   @({
   (control-screen-output-and-maybe-replay verbose event-p form)
   })

   <p>where @('verbose') is not evaluated.</p>

   <p>If @('verbose') is @('t'), @(''t'), @('nil'), or @(''nil'), this is just
   @(tsee control-screen-output), and @(':event-p') is ignored.  So suppose
   otherwise for the rest of this documentation.</p>

   <p>In that case, @('(control-screen-output nil form)') is evaluated, and
   then if evaluation fails, @('(control-screen-output t form)') is
   subsequently evaluated so that the failure can be seen with more output.
   Moreover, the value of @(':event-p') is relevant, with the following two
   cases.</p>

   <ul>

   <li>For @(':event-p t'), the call of
   @('control-screen-output-and-maybe-replay') can go into a book, but @('form')
   must be a legal event form (see @(see embedded-event-form)).</li>

   <li>For @(':event-p nil'), the call of
   @('control-screen-output-and-maybe-replay') cannot go into a book, but
   @('form') need not be a legal event form.</li>

   </ul>"

  (let ((verbose (maybe-unquote verbose)))
    (cond ((booleanp verbose)
           (control-screen-output verbose form))
          (t
           (let ((form-nil (control-screen-output nil form))
                 (form-t (control-screen-output t form)))
             (cond
              (event-p
               `(make-event
                 '(:or ,form-nil
                       (with-output
                         :off :all
                         :on error
                         :stack :push
                         (progn
                           (value-triple (cw "~%===== VERBOSE REPLAY: =====~|"))
                           (with-output :stack :pop ,form-t))))))
              (t `(mv-let (erp val state)
                    ,form-nil
                    (cond (erp (prog2$ (cw "~%===== VERBOSE REPLAY: =====~|")
                                       ,form-t))
                          (t (value val)))))))))))

(define manage-screen-output-aux (verbose (form pseudo-event-formp) bangp)
  :returns (form-with-output-managed pseudo-event-formp :hyp :guard)
  (cond ((maybe-unquote verbose) form)
        (t (let ((output-names (remove1 'error *valid-output-names*)))
             `(,(if bangp 'with-output! 'with-output)
               :off ,output-names
               :gag-mode nil
               ,form)))))

(define manage-screen-output (verbose (form pseudo-event-formp))
  :returns (form-with-output-managed pseudo-event-formp :hyp :guard)
  :parents (user-interface)
  :short "Manage the screen output generated from an event form."
  :long
  "<p>
   If @('verbose') is not @('nil') or @(''nil'), keep all screen output.
   If @('verbose') is @('nil') or @(''nil'), suppress all non-error screen
   output.
   </p>
   <p>
   This function can be used in a macro of the following form:
   @({
     (defmacro mac (... &key verbose ...)
       (manage-screen-output verbose `(make-event ...)))
   })
   Invoking @('mac') at the ACL2 top-level will submit the event,
   with the screen output managed by @('verbose').
   </p>
   <p>
   Note that if @('form') is an event (see @(see embedded-event-form)), then
   @('(manage-screen-output verbose form)') evaluates to an event.
   </p>"
  (manage-screen-output-aux verbose form nil))

(defsection cw-event
  :parents (user-interface)
  :short "Event form of @(tsee cw)."
  :long
  "<p>
   When this macro is processed as an event,
   its arguments are passed to @(tsee cw).
   </p>
   @(def cw-event)"
  (defmacro cw-event (str &rest args)
    `(value-triple (cw ,str ,@args))))

(defsection make-event-terse
  :parents (user-interface)
  :short "A variant of @(tsee make-event) with terser screen output."
  :long
  "<p>
   We wrap a normal @(tsee make-event)
   in a @(tsee with-output) that removes all the screen output
   except possibly errors.
   We also suppress the concluding error message of @(tsee make-event),
   via @(':on-behalf-of :quiet!').
   </p>
   <p>
   The rationale for not suppressing error output is that, otherwise,
   @('make-event-terse') will fail silently in case of an error.
   However, if errors were already suppressed,
   this form does not enable them.
   </p>
   <p>
   We save, via @(':stack :push'), the current state of the outputs,
   so that, inside the form passed to @('make-event-terse'),
   that output state can be selectively restored for some sub-forms.
   That output state can be restored via @('(with-output :stack :pop ...)'),
   or by using the @(tsee restore-output) or @(tsee restore-output?) utilities.
   </p>
   <p>
   Currently @('make-event-terse') does not support
   @(tsee make-event)'s @(':check-expansion') and @(':expansion?'),
   but it could be extended to support them and pass them to @(tsee make-event).
   </p>
   <p>
   @('make-event-terse') may be useful in event-generating macros.
   </p>"
  (defmacro make-event-terse (form)
    `(with-output
       :gag-mode nil
       :off ,(remove-eq 'error *valid-output-names*)
       :stack :push
       (make-event ,form :on-behalf-of :quiet!))))

(define restore-output ((form pseudo-event-formp))
  :returns (form-with-output-restored pseudo-event-formp)
  :parents (user-interface)
  :short "Wrap a form to have it produce screen output
          according to previously saved screen output settings."
  :long
  "<p>
   This wraps the form in a @('(with-output :stack :pop ...)').
   It can be used on a sub-form
   of the form passed to a @(tsee make-event-terse).
   </p>"
  `(with-output :stack :pop ,form))

(define restore-output? ((yes/no booleanp) (form pseudo-event-formp))
  :returns (form-maybe-with-output-restored pseudo-event-formp
                                            :hyp (pseudo-event-formp form))
  :parents (user-interface)
  :short "Conditionally wrap a form to have it produce screen output
          according to previously saved screen output settings."
  :long
  "<p>
   This leaves the form unchanged if the boolean is @('nil'),
   otherwise it calls @(tsee restore-output) on it.
   </p>"
  (if yes/no
      (restore-output form)
    form))

;*=====================================================================*/
;*    .../project/bigloo/api/gstreamer/src/Llib/gstmessage.scm         */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Jan  3 09:21:35 2008                          */
;*    Last change :  Wed Oct 14 11:00:43 2009 (serrano)                */
;*    Copyright   :  2008-09 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    GstMessage                                                       */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __gstreamer_gstmessage
   
   (include "gst.sch")
   
   (import  __gstreamer_gsterror
	    __gstreamer_gstobject
	    __gstreamer_gststructure)

   (export  (class gst-message
	       (%gst-message-init)
	       ($builtin::$gst-message (default ($gst-message-nil)))
	       ($finalizer::obj read-only (default #f))
	       (type::$gst-message-type
		read-only
		(get (lambda (o)
			($gst-message-get-type
			 (gst-message-$builtin o)))))
	       (type-name::string
		read-only
		(get (lambda (o)
			($gst-message-get-type-name
			 (gst-message-$builtin o)))))
	       (src::obj
		read-only
		(get (lambda (o)
			($gst-message-get-src
 			 (gst-message-$builtin o))))))

	    (%gst-message-init ::gst-message)
	    ($make-gst-message::obj ::$gst-message ::obj)

	    (gst-message-error-string::string ::gst-message)
	    (gst-message-info-string::string ::gst-message)
	    (gst-message-warning-string::string ::gst-message)
	    (gst-message-tag-list::pair-nil ::gst-message)
	    (gst-message-new-state::symbol ::gst-message)
	    (gst-message-old-state::symbol ::gst-message)
	    (gst-message-pending-state::symbol ::gst-message)
	    (gst-message-structure ::gst-message)

	    (gst-message-tag?::bool ::gst-message)
	    (gst-message-eos?::bool ::gst-message)
	    (gst-message-async-start?::bool ::gst-message)
	    (gst-message-async-done?::bool ::gst-message)
	    (gst-message-error?::bool ::gst-message)
	    (gst-message-unknown?::bool ::gst-message)
	    (gst-message-warning?::bool ::gst-message)
	    (gst-message-buffering?::bool ::gst-message)
	    (gst-message-state-changed?::bool ::gst-message)
	    (gst-message-state-dirty?::bool ::gst-message)

	    (gst-message-new-application::gst-message ::gst-object ::gst-structure)
	    (gst-message-new-custom::gst-message ::$gst-message-type ::gst-object ::gst-structure)
	    (gst-message-new-element::gst-message ::gst-object ::gst-structure)
	    (gst-message-new-eos::gst-message ::gst-object)
	    (gst-message-new-state-changed::gst-message ::gst-object ::$gst-state ::$gst-state ::$gst-state)
	    (gst-message-new-state-dirty::gst-message ::gst-object)
	    (gst-message-new-async-done::gst-message ::gst-object)
	    (gst-message-new-latency::gst-message ::gst-object))
	    
   (extern  (export $make-gst-message "bgl_gst_message_new")))

;*---------------------------------------------------------------------*/
;*    %gst-message-init ::gst-message ...                              */
;*---------------------------------------------------------------------*/
(define (%gst-message-init o::gst-message)
   (with-access::gst-message o ($builtin $finalizer)
      (when ($gst-message-null? $builtin)
	 (raise (instantiate::&gst-create-error
		   (proc '%gst-message-init)
		   (msg "Illegal gst-message")
		   (obj o))))
      (when (> (bigloo-debug) (gst-debug-level)) (%gst-object-init-debug o))
      (cond
	 ((procedure? $finalizer)
	  ($gst-add-finalizer! o $finalizer))
	 ($finalizer
	  ($gst-add-finalizer! o (lambda (o)
				    (when (> (bigloo-debug) (gst-debug-level))
				       (%gst-object-finalize-debug o))
				    ($gst-message-unref!
				     (gst-message-$builtin o))))))
      o))

;*---------------------------------------------------------------------*/
;*    object-display ...                                               */
;*---------------------------------------------------------------------*/
(define-method (object-display o::gst-message . port)
   (let ((p (if (pair? port) (car port) (current-output-port))))
      (display "<" p)
      (display (find-runtime-type o) p)
      (display " refcount=" p)
      (display ($gst-object-refcount (gst-message-$builtin o)) p)
      (display " type-name=" p)
      (display (gst-message-type-name o) p)
      (display ">" p)))

;*---------------------------------------------------------------------*/
;*    $gst-state->obj ...                                              */
;*---------------------------------------------------------------------*/
(define ($gst-state->obj state)
   (cond
      ((=fx state $gst-state-void-pending) 'void-pending)
      ((=fx state $gst-state-null) 'null)
      ((=fx state $gst-state-ready) 'ready)
      ((=fx state $gst-state-paused) 'paused)
      ((=fx state $gst-state-playing) 'playing)
      (else 'unknown)))

;*---------------------------------------------------------------------*/
;*    $make-gst-message ...                                            */
;*---------------------------------------------------------------------*/
(define ($make-gst-message message::$gst-message finalizer)
   (instantiate::gst-message
      ($builtin message)
      ($finalizer finalizer)))

;*---------------------------------------------------------------------*/
;*    gst-message-error-string ...                                     */
;*---------------------------------------------------------------------*/
(define (gst-message-error-string msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-error)
       ($gst-message-error-string (gst-message-$builtin msg))
       (bigloo-type-error 'gst-message-error-string 'gst-message-error msg)))
   
;*---------------------------------------------------------------------*/
;*    gst-message-info-string ...                                      */
;*---------------------------------------------------------------------*/
(define (gst-message-info-string msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-info)
       ($gst-message-info-string (gst-message-$builtin msg))
       (bigloo-type-error 'gst-message-info-string 'gst-message-info msg)))
   
;*---------------------------------------------------------------------*/
;*    gst-message-warning-string ...                                   */
;*---------------------------------------------------------------------*/
(define (gst-message-warning-string msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-warning)
       ($gst-message-warning-string (gst-message-$builtin msg))
       (bigloo-type-error 'gst-message-warning-string 'gst-message-warning msg)))
   
;*---------------------------------------------------------------------*/
;*    gst-message-tag-list ...                                         */
;*---------------------------------------------------------------------*/
(define (gst-message-tag-list msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-tag)
       ($gst-message-tag-list (gst-message-$builtin msg))
       (bigloo-type-error 'gst-message-tag-list 'gst-message-tag msg)))

;*---------------------------------------------------------------------*/
;*    gst-message-new-state ...                                        */
;*---------------------------------------------------------------------*/
(define (gst-message-new-state msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-state-changed)
       ($gst-state->obj ($gst-message-new-state (gst-message-$builtin msg)))
       (bigloo-type-error 'gst-message-new-state 'gst-message-state-changed msg)))

;*---------------------------------------------------------------------*/
;*    gst-message-old-state ...                                        */
;*---------------------------------------------------------------------*/
(define (gst-message-old-state msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-state-changed)
       ($gst-state->obj ($gst-message-old-state (gst-message-$builtin msg)))
       (bigloo-type-error 'gst-message-old-state 'gst-message-state-changed msg)))

;*---------------------------------------------------------------------*/
;*    gst-message-pending-state ...                                    */
;*---------------------------------------------------------------------*/
(define (gst-message-pending-state msg::gst-message)
   (if (=fx (gst-message-type msg) $gst-message-state-changed)
       ($gst-state->obj ($gst-message-pending-state (gst-message-$builtin msg)))
       (bigloo-type-error 'gst-message-pending-state 'gst-message-state-changed msg)))

;*---------------------------------------------------------------------*/
;*    gst-message-structure ...                                        */
;*---------------------------------------------------------------------*/
(define (gst-message-structure msg::gst-message)
   (instantiate::gst-structure
      ($builtin ($gst-message-get-structure (gst-message-$builtin msg)))
      ($finalizer #f)))

;*---------------------------------------------------------------------*/
;*    gst-message-tag? ...                                             */
;*---------------------------------------------------------------------*/
(define (gst-message-tag? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-tag))

;*---------------------------------------------------------------------*/
;*    gst-message-async-start? ...                                     */
;*---------------------------------------------------------------------*/
(define (gst-message-async-start? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-async-start))

;*---------------------------------------------------------------------*/
;*    gst-message-async-done? ...                                      */
;*---------------------------------------------------------------------*/
(define (gst-message-async-done? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-async-done))

;*---------------------------------------------------------------------*/
;*    gst-message-eos? ...                                             */
;*---------------------------------------------------------------------*/
(define (gst-message-eos? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-eos))

;*---------------------------------------------------------------------*/
;*    gst-message-error? ...                                           */
;*---------------------------------------------------------------------*/
(define (gst-message-error? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-error))

;*---------------------------------------------------------------------*/
;*    gst-message-unknown? ...                                         */
;*---------------------------------------------------------------------*/
(define (gst-message-unknown? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-unknown))

;*---------------------------------------------------------------------*/
;*    gst-message-warning? ...                                         */
;*---------------------------------------------------------------------*/
(define (gst-message-warning? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-warning))

;*---------------------------------------------------------------------*/
;*    gst-message-buffering? ...                                       */
;*---------------------------------------------------------------------*/
(define (gst-message-buffering? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-buffering))

;*---------------------------------------------------------------------*/
;*    gst-message-state-changed? ...                                   */
;*---------------------------------------------------------------------*/
(define (gst-message-state-changed? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-state-changed))

;*---------------------------------------------------------------------*/
;*    gst-message-state-dirty? ...                                     */
;*---------------------------------------------------------------------*/
(define (gst-message-state-dirty? msg::gst-message)
   (=fx (gst-message-type msg) $gst-message-state-dirty))

;*---------------------------------------------------------------------*/
;*    gst-message-new-application ...                                  */
;*---------------------------------------------------------------------*/
(define (gst-message-new-application src::gst-object struct::gst-structure)
   ($make-gst-message
    ($gst-message-new-application (gst-object-$builtin src)
				  ($gst-structure (gst-structure-$builtin struct)))
    #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-custom ...                                       */
;*---------------------------------------------------------------------*/
(define (gst-message-new-custom type src struct)
   ($make-gst-message
    ($gst-message-new-custom type
			     (gst-object-$builtin src)
			     ($gst-structure (gst-structure-$builtin struct)))
    #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-element ...                                      */
;*---------------------------------------------------------------------*/
(define (gst-message-new-element src::gst-object struct::gst-structure)
   ($make-gst-message
    ($gst-message-new-element (gst-object-$builtin src)
			      ($gst-structure (gst-structure-$builtin struct)))
    #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-eos ...                                          */
;*---------------------------------------------------------------------*/
(define (gst-message-new-eos src::gst-object)
   ($make-gst-message ($gst-message-new-eos (gst-object-$builtin src)) #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-state-changed ...                                */
;*---------------------------------------------------------------------*/
(define (gst-message-new-state-changed src::gst-object old new pending)
   ($make-gst-message ($gst-message-new-state-changed (gst-object-$builtin src)
						      old
						      new
						      pending)
		      #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-state-dirty ...                                  */
;*---------------------------------------------------------------------*/
(define (gst-message-new-state-dirty src::gst-object)
   ($make-gst-message ($gst-message-new-state-dirty (gst-object-$builtin src))
		      #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-async-done ...                                   */
;*---------------------------------------------------------------------*/
(define (gst-message-new-async-done src::gst-object)
   ($make-gst-message ($gst-message-new-async-done (gst-object-$builtin src))
		      #t))

;*---------------------------------------------------------------------*/
;*    gst-message-new-latency ...                                      */
;*---------------------------------------------------------------------*/
(define (gst-message-new-latency src::gst-object)
   ($make-gst-message ($gst-message-new-latency (gst-object-$builtin src)) #t))

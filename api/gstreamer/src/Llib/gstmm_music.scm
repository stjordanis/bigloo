;*=====================================================================*/
;*    .../project/bigloo/api/gstreamer/src/Llib/gstmm_music.scm        */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Jan 31 07:15:14 2008                          */
;*    Last change :  Tue Nov 15 18:01:38 2011 (serrano)                */
;*    Copyright   :  2008-11 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    This module implements a Gstreamer backend for the               */
;*    multimedia MUSIC class.                                          */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __gstreamer_multimedia_music
   
   (library multimedia pthread)
   
   (include "gst.sch")
   
   (import  __gstreamer_gstreamer
	    __gstreamer_gstobject
	    __gstreamer_gstelement
	    __gstreamer_gstregistry
	    __gstreamer_gstelementfactory
	    __gstreamer_gstpluginfeature
	    __gstreamer_gstpad
	    __gstreamer_gstbus
	    __gstreamer_gstbin
	    __gstreamer_gstcaps
	    __gstreamer_gststructure
	    __gstreamer_gstpipeline
	    __gstreamer_gstelement
	    __gstreamer_gstmessage)
   
   (export  (class gstmusic::music
	       
	       (%audiosrc (default #unspecified))
	       (%audiosink (default #unspecified))
	       (%audiomixer (default #unspecified))
	       (%audiodecode (default #unspecified))
	       (%audioconvert (default #unspecified))
	       (%audioresample (default #unspecified))
	       (%pipeline (default #f))
	       
	       (%playlist::pair-nil (default '()))
	       (%meta::pair-nil (default '()))
	       (%tag::obj (default '())))))

;*---------------------------------------------------------------------*/
;*    debug-mutex-lock! ...                                            */
;*---------------------------------------------------------------------*/
(define (debug-mutex-lock! mutex)
   ;; (tprint ">>> mutex-lock! " mutex)
   (unless ((@ mutex-lock! __thread)  mutex 100000)
      (tprint "**** CANNOT LOCK MUTEX AFTER 100000: " mutex)
      ((@ mutex-lock! __thread) mutex)))

;*---------------------------------------------------------------------*/
;*    debug-mutex-unlock! ...                                          */
;*---------------------------------------------------------------------*/
(define (debug-mutex-unlock! mutex)
   ;; (tprint "<<< mutex-unlock! " mutex)
   ((@ mutex-unlock! __thread)  mutex))

;*---------------------------------------------------------------------*/
;*    debug-condv-wait! ...                                            */
;*---------------------------------------------------------------------*/
(define (debug-condv-wait! cv mutex)
   (tprint "~~~ waiting on " mutex)
    ((@ condition-variable-wait! __thread) cv mutex))
   
;*---------------------------------------------------------------------*/
;*    mutex-lock! ...                                                  */
;*---------------------------------------------------------------------*/
(define-expander mutex-lock!
   (lambda (x e)
      (e `(debug-mutex-lock! ,@(cdr x)) e)))

;*---------------------------------------------------------------------*/
;*    mutex-unlock! ...                                                */
;*---------------------------------------------------------------------*/
(define-expander mutex-unlock!
   (lambda (x e)
      (e `(debug-mutex-unlock! ,@(cdr x)) e)))

;*---------------------------------------------------------------------*/
;*    condition-variable-wait! ...                                     */
;*---------------------------------------------------------------------*/
(define-expander condition-variable-wait!
   (lambda (x e)
      (e `(debug-condv-wait! ,@(cdr x)) e)))

;*---------------------------------------------------------------------*/
;*    with-lock ...                                                    */
;*---------------------------------------------------------------------*/
(define-expander with-lock
   (lambda (x e)
      (e `(unwind-protect
	     (begin
		(mutex-lock! ,(cadr x))
		(,(caddr x)))
	     (mutex-unlock! ,(cadr x)))
	 e)))

;*---------------------------------------------------------------------*/
;*    music-init ::gstmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-init o::gstmusic)
   (with-access::gstmusic o (%pipeline
			     %audiosrc
			     %audiodecode %audioconvert %audioresample
			     %audiomixer %audiosink
			     %mutex)
      (call-next-method)
      (with-lock %mutex
	 (lambda ()
	    ;; initialize the pipeline
	    (unless (isa? %pipeline gst-element)
	       (unless (isa? %audiosrc gst-element)
		  (set! %audiosrc (gst-element-factory-make "bglportsrc"))
		  (unless (isa? %audiosrc gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audiosrc"
			      o)))
	       (unless (isa? %audiosink gst-element)
		  (let ((f (gst-element-factory-find "autoaudiosink")))
		     (if (isa? f gst-element-factory)
			 (set! %audiosink (gst-element-factory-create f))
			 (set! %audiosink (find-best-ranked-audio-sink))))
		  (unless (isa? %audiosink gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audiosink"
			      o)))
	       (unless (isa? %audiomixer gst-element)
		  (let ((f (gst-element-factory-make "volume")))
		     (set! %audiomixer (gst-element-factory-make "volume")))
		  (unless (isa? %audiomixer gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audiomixer"
			      o)))
	       (unless (isa? %audiodecode gst-element)
		  (set! %audiodecode (gst-element-factory-make "decodebin"))
		  (unless (isa? %audiodecode gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audiodecode"
			      o)))
	       (unless (isa? %audioconvert gst-element)
		  (set! %audioconvert (gst-element-factory-make "audioconvert"))
		  (unless (isa? %audioconvert gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audioconvert"
			      o)))
	       (unless (isa? %audioresample gst-element)
		  (set! %audioresample (gst-element-factory-make "audioresample"))
		  (unless (isa? %audioresample gst-element)
		     (error '|music-init ::gstmusic|
			      "Cannot create audioresampler"
			      o)))
	       (set! %pipeline (instantiate::gst-pipeline))
	       (unless (isa? %audioresample gst-element)
		  (error '|music-init ::gstmusic|
			   "Cannot create pipeline"
			   o))
	       
	       (gst-bin-add! %pipeline
			     %audiosrc
			     %audiodecode
			     %audioconvert
			     %audioresample
			     %audiomixer
			     %audiosink)
	       
	       (gst-element-link! %audiosrc
				  %audiodecode)
	       (gst-element-link! %audioconvert
				  %audioresample
				  %audiomixer
				  %audiosink)
	       
	       (gst-object-connect! %audiodecode
				    "pad-added"
				    (lambda (el pad)
				       (let ((p (gst-element-pad %audioconvert
								 "sink")))
					  (gst-pad-link! pad p)))))))))

;*---------------------------------------------------------------------*/
;*    find-best-ranked-audio-sink ...                                  */
;*---------------------------------------------------------------------*/
(define (find-best-ranked-audio-sink)
   (let* ((lall (gst-registry-element-factory-list))
	  (lsinkaudio (filter (lambda (f)
				 (with-access::gst-element-factory f (klass)
				    (string-ci=? klass "sink/audio")))
			 lall))
	  (lrank (sort lsinkaudio
		       (lambda (f1 f2)
			  (with-access::gst-element-factory f1 ((rank1 rank))
			     (with-access::gst-element-factory f2 ((rank2 rank))
				(>fx rank1 rank2)))))))
      (if (null? lrank)
	  (error 'music-init
		 "Cannot find audio sink"
		 (map (lambda (e) (with-access::gst-element-factory e (name) name)) lall))
	  (gst-element-factory-create (car lrank) "gstmm-sink"))))

;*---------------------------------------------------------------------*/
;*    music-event-loop-inner ::gstmusic ...                            */
;*---------------------------------------------------------------------*/
(define-method (music-event-loop-inner o::gstmusic frequency::long onstate onmeta onerror onvol onplaylist)
   (with-access::gstmusic o (%mutex %loop-mutex %pipeline %status %abort-loop %meta)
      (when %pipeline
	 (mutex-lock! %loop-mutex)
	 (with-access::musicstatus %status (volume playlistid state song songpos songlength bitrate err playlistlength)
	    (set! state 'init)
	    (let ((bus (unwind-protect
			  (with-access::gst-pipeline %pipeline (bus) bus)
			  (mutex-unlock! %loop-mutex))))
	       ;; store the current volume level
	       (music-volume-get o)
	       (let loop ((vol volume)
			  (pid playlistid)
			  (meta #f))
		  (mutex-lock! %loop-mutex)
		  (let* ((msg (unwind-protect
				 (gst-bus-poll bus :timeout #l1167000000)
				 (mutex-unlock! %loop-mutex)))
			 (nvol volume)
			 (npid playlistid))
		     (cond
			(%abort-loop
			   ;; we are done
			   #f)
			((not msg)
			 ;; time out
			 (cond
			    ((not (=fx vol nvol))
			     (when onvol (onvol nvol)))
			    ((not (=fx pid npid))
			     (when onplaylist
				(onplaylist %status))
			     (sleep 10)))
			 #f)
			((gst-message-eos? msg)
			 ;; end of stream
			 (mutex-lock! %mutex)
			 (gst-element-state-set! %pipeline 'null)
			 (set! state 'ended)
			 (set! songpos 0)
			 (set! %meta '())
			 (set! meta #f)
			 (mutex-unlock! %mutex)
			 (when onstate (onstate %status))
			 (when (<fx song (-fx playlistlength 1))
			    (mutex-lock! %mutex)
			    (set! song (+fx 1 song))
			    (mutex-unlock! %mutex)
			    (music-play o)
			    (when (>=fx volume 0)
			       (music-volume-set! o volume))))
			((gst-message-state-changed? msg)
			 ;; state changed
			 (let ((nstate (case (gst-message-new-state msg)
					  ((playing) 'play)
					  ((paused) 'pause)
					  ((ready) 'stop)
					  ((null) 'stop))))
			    (mutex-lock! %mutex)
			    (if (eq? nstate state)
				(mutex-unlock! %mutex)
				(begin
				   (set! state nstate)
				   (when (isa? %pipeline gst-element)
				      (set! songpos (music-position o))
				      (set! songlength (music-duration o)))
				   (mutex-unlock! %mutex)
				   (when onstate (onstate %status))
				   ;; at this moment we don't know if we will
				   ;; see tags, so we emit a fake onmeta
				   (when (and onmeta (not meta) (eq? state 'play))
				      (let* ((plist (music-playlist-get o))
					     (file (list-ref plist song)))
					 (onmeta (or (file-musictag file) file))))))
			    (begin
			       (when (and (eq? nstate 'play) (>=fx volume 0))
				  ;; Some gstreamer player are wrong and
				  ;; tend to forget the volume level. As a
				  ;; workaround, we enforce it each time we
				  ;; receive a play state change message.
				  (music-volume-set! o volume)))))
			((and (gst-message-tag? msg) onmeta)
			 ;; tag found
			 (mutex-lock! %mutex)
			 (let ((notify #f))
			    (for-each (lambda (tag)
					 (let ((key (string->symbol (car tag))))
					    (case key
					       ((bitrate)
						(set! bitrate
						   (elong->fixnum
						      (/elong (cdr tag) #e1000))))
					       ((artist title album year)
						(set! notify #t)
						(set! %meta
						   (cons (cons key (cdr tag))
						      %meta)))
					       (else
						#unspecified))))
			       (gst-message-tag-list msg))
			    (mutex-unlock! %mutex)
			    (when notify
			       (set! meta #t)
			       (onmeta %meta))))
			((gst-message-warning? msg)
			 ;; warning
			 (mutex-lock! %mutex)
			 (set! err (gst-message-warning-string msg))
			 (mutex-unlock! %mutex)
			 (when onerror (onerror err)))
			((gst-message-error? msg)
			 ;; error
			 (mutex-lock! %mutex)
			 (set! err (gst-message-error-string msg))
			 (mutex-unlock! %mutex)
			 (when onerror (onerror err)))
			((gst-message-state-dirty? msg)
			 ;; refresh
			 (when onstate (onstate %status))))
		     
		     
		     (unless %abort-loop
			;; wait to give a chance to other threads
			;; to acquire the lock
			(sleep 113)
			(loop nvol npid meta)))))))))

;*---------------------------------------------------------------------*/
;*    reset-sans-lock! ...                                             */
;*---------------------------------------------------------------------*/
(define (reset-sans-lock! o::gstmusic)
   (with-access::gstmusic o (%pipeline)
      (when (isa? %pipeline gst-element)
	 (with-access::gst-pipeline %pipeline (bus)
	    (let ((msg (gst-message-new-state-dirty %pipeline)))
	       (gst-bus-post bus msg))))))

;*---------------------------------------------------------------------*/
;*    music-event-loop-reset! ::gstmusic ...                           */
;*---------------------------------------------------------------------*/
(define-method (music-event-loop-reset! o::gstmusic)
   (with-access::gstmusic o (%mutex)
      (mutex-lock! %mutex)
      (unwind-protect
	 (reset-sans-lock! o)
	 (mutex-unlock! %mutex))))

;*---------------------------------------------------------------------*/
;*    music-event-loop-abort! ::gstmusic ...                           */
;*---------------------------------------------------------------------*/
(define-method (music-event-loop-abort! o::gstmusic)
   (with-access::gstmusic o (%loop-mutex %loop-condv %abort-loop)
      #;(mutex-lock! %loop-mutex)
      (unless %abort-loop
	 (set! %abort-loop #t)
	 (reset-sans-lock! o)
	 #;(condition-variable-wait! %loop-condv %loop-mutex))
      #;(mutex-unlock! %loop-mutex)))

;*---------------------------------------------------------------------*/
;*    music-close ::gstmusic ...                                       */
;*---------------------------------------------------------------------*/
(define-method (music-close o::gstmusic)
   (with-access::gstmusic o (%pipeline %mutex)
      (let ((closed (with-lock %mutex (lambda () (music-closed? o)))))
	 (unless closed
	    (call-next-method)
	    (with-lock %mutex
	       (lambda ()
		  (when (isa? %pipeline gst-element)
		     (gst-element-state-set! %pipeline 'null))))))))

;*---------------------------------------------------------------------*/
;*    music-closed? ::gstmusic ...                                     */
;*---------------------------------------------------------------------*/
(define-method (music-closed? o::gstmusic)
   (with-access::gstmusic o (%pipeline)
      (not (isa? %pipeline gst-element))))

;*---------------------------------------------------------------------*/
;*    music-reset! ::gstmusic ...                                      */
;*---------------------------------------------------------------------*/
(define-method (music-reset! o::gstmusic)
   (music-close o))
   
;*---------------------------------------------------------------------*/
;*    music-playlist-get ::gstmusic ...                                */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-get gstmusic::gstmusic)
   (with-access::gstmusic gstmusic (%playlist)
      %playlist))

;*---------------------------------------------------------------------*/
;*    music-playlist-add! ::gstmusic ...                               */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-add! gstmusic::gstmusic n)
   (call-next-method)
   (with-access::gstmusic gstmusic (%mutex %playlist %status)
      (with-lock %mutex
	 (lambda ()
	    (set! %playlist (append %playlist (list n)))
	    (with-access::musicstatus %status (playlistid playlistlength)
	       (set! playlistid (+fx 1 playlistid))
	       (set! playlistlength (+fx 1 playlistlength)))))))

;*---------------------------------------------------------------------*/
;*    music-playlist-delete! ::gstmusic ...                            */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-delete! gstmusic::gstmusic n)
   (with-access::gstmusic gstmusic (%mutex %playlist %status)
      (with-lock %mutex
	 (lambda ()
	    (set! %playlist (delete! n %playlist string=?))
	    (with-access::musicstatus %status (playlistid playlistlength)
	       (when (and (>=fx n 0) (<fx n playlistlength))
		  (set! %playlist (remq! (list-ref %playlist n) %playlist))
		  (set! playlistid (+fx 1 playlistid))
		  (set! playlistlength (length %playlist))))))))

;*---------------------------------------------------------------------*/
;*    music-playlist-clear! ::gstmusic ...                             */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-clear! gstmusic::gstmusic)
   (with-access::gstmusic gstmusic (%mutex %playlist %status)
      (with-lock %mutex
	 (lambda ()
	    (set! %playlist '())
	    (with-access::musicstatus %status (playlistlength song)
	       (set! song 0)
	       (set! playlistlength 0))))))

;*---------------------------------------------------------------------*/
;*    set-song! ...                                                    */
;*---------------------------------------------------------------------*/
(define (set-song! o i)
   (with-access::gstmusic o (%status %playlist)
      (cond
	 ((<fx i 0)
	  (raise
	   (instantiate::&io-error
	      (proc 'set-song!)
	      (msg (format "No such song: ~a" i))
	      (obj %playlist))))
	 ((>=fx i (length %playlist))
	  #f)
	 (else
	  (let ((m (list-ref %playlist i)))
	     (with-access::musicstatus %status (song)
		(set! song i))
	     m)))))

;*---------------------------------------------------------------------*/
;*    gstmm-charset-convert ...                                        */
;*---------------------------------------------------------------------*/
(define-macro (gstmm-charset-convert str)
   (case (os-charset)
      ((UTF-8)
       str)
      ((UCS-2)
       `(utf8-string->ucs2-string ,str))
      ((CP-1252)
       `(utf8->cp1252 ,str))
      (else
       `(utf8->iso-latin ,str))))

;*---------------------------------------------------------------------*/
;*    music-play ::gstmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-play o::gstmusic . song)
   (with-access::gstmusic o (%mutex %pipeline %audiosrc %status %playlist)
      (with-lock %mutex
	 (lambda ()
	    (unless (isa? %pipeline gst-element)
	       (error '|music-play ::gstmusic|
			"Player closed (or badly initialized)"
			o))
	    (when (pair? %playlist)
	       (let ((url (if (pair? song)
			      (if (not (integer? (car song)))
				  (bigloo-type-error '|music-play ::gstmusic|
				     'int
				     (car song))
				  (set-song! o (car song)))
			      (with-access::musicstatus %status (song)
				 (set-song! o song)))))
		  (when (string? url)
		     (let ((uri (gstmm-charset-convert url)))
			(gst-element-state-set! %pipeline 'null)
			(gst-element-state-set! %pipeline 'ready)
			(gst-object-property-set! %audiosrc :uri uri)
			(gst-element-state-set! %pipeline 'playing)))))))))

;*---------------------------------------------------------------------*/
;*    music-seek ::gstmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-seek o::gstmusic pos . song)
   (with-access::gstmusic o (%mutex %pipeline)
      (with-lock %mutex
	 (lambda ()
	    (when (pair? song)
	       (if (not (integer? (car song)))
		   (bigloo-type-error '|music-seek ::gstmusic| 'int (car song))
		   (set-song! o (car song))))
	    (when (isa? %pipeline gst-element)
	       (gst-element-seek %pipeline
		  (*llong (fixnum->llong pos) #l1000000000)))))))

;*---------------------------------------------------------------------*/
;*    music-stop ::gstmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-stop o::gstmusic)
   (with-access::gstmusic o (%mutex %pipeline)
      (with-lock %mutex
	 (lambda ()
	    (when (isa? %pipeline gst-element)
	       (gst-element-state-set! %pipeline 'null)
	       (gst-element-state-set! %pipeline 'ready))))))
   
;*---------------------------------------------------------------------*/
;*    music-pause ::gstmusic ...                                       */
;*---------------------------------------------------------------------*/
(define-method (music-pause o::gstmusic)
   (with-access::gstmusic o (%mutex %pipeline %status)
      (with-lock %mutex
	 (lambda ()
	    (when (isa? %pipeline gst-element)
	       (with-access::musicstatus %status (state)
		  (if (eq? state 'pause)
		      (gst-element-state-set! %pipeline 'playing)
		      (gst-element-state-set! %pipeline 'paused))))))))

;*---------------------------------------------------------------------*/
;*    music-position ...                                               */
;*---------------------------------------------------------------------*/
(define (music-position o)
   ;; this function assumes that %pipeline is still valid (i.e., the
   ;; gstmm music player has not been closed yet)
   (with-access::gstmusic o (%pipeline)
      (llong->fixnum
	 (/llong (gst-element-query-position %pipeline) #l1000000000))))

;*---------------------------------------------------------------------*/
;*    music-duration ...                                               */
;*---------------------------------------------------------------------*/
(define (music-duration o)
   ;; this function assumes that %pipeline is still valid (i.e., the
   ;; gstmm music player has not been closed yet)
   (with-access::gstmusic o (%pipeline)
      (llong->fixnum
	 (/llong (gst-element-query-duration %pipeline) #l1000000000))))

;*---------------------------------------------------------------------*/
;*    music-update-status! ::gstmusic ...                              */
;*---------------------------------------------------------------------*/
(define-method (music-update-status! o::gstmusic status::musicstatus)
   (with-access::gstmusic o (%mutex %pipeline)
      (with-access::musicstatus status (state songpos songlength volume)
	 (mutex-lock! %mutex)
	 (if (isa? %pipeline gst-element)
	     (begin
		(set! songpos (music-position o))
		(set! songlength (music-duration o))
		(set! volume (music-volume-get o)))
	     (set! state 'stop))
	 (mutex-unlock! %mutex)
	 status)))

;*---------------------------------------------------------------------*/
;*    music-status ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (music-status o::gstmusic)
   (with-access::music o (%status)
      (music-update-status! o %status)
      %status))

;*---------------------------------------------------------------------*/
;*    music-song ::gstmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-song o::gstmusic)
   (with-access::gstmusic o (%mutex %status)
      (with-lock %mutex
	 (lambda ()
	    (with-access::musicstatus %status (song) song)))))

;*---------------------------------------------------------------------*/
;*    music-songpos ::gstmusic ...                                     */
;*---------------------------------------------------------------------*/
(define-method (music-songpos o::gstmusic)
   ;; this function assumes that %pipeline is still valid (i.e., the
   ;; gstmm music player has not been closed yet)
   (with-access::gstmusic o (%pipeline)
      (llong->fixnum
	 (/llong (gst-element-query-position %pipeline) #l1000000000))))

;*---------------------------------------------------------------------*/
;*    music-meta ...                                                   */
;*---------------------------------------------------------------------*/
(define-method (music-meta o::gstmusic)
   (with-access::gstmusic o (%meta)
      %meta))

;*---------------------------------------------------------------------*/
;*    music-volume-get ::gstmusic ...                                  */
;*---------------------------------------------------------------------*/
(define-method (music-volume-get o::gstmusic)
   (with-access::gstmusic o (%status %audiomixer)
      (if (isa? %audiomixer gst-element)
	  (let ((vol (inexact->exact
		      (* 100 (gst-object-property %audiomixer :volume)))))
	     (with-access::musicstatus %status (volume)
		(set! volume vol))
	     vol)
	  0)))

;*---------------------------------------------------------------------*/
;*    music-volume-set! ::gstmusic ...                                 */
;*---------------------------------------------------------------------*/
(define-method (music-volume-set! o::gstmusic vol)
   (with-access::gstmusic o (%status %audiomixer)
      (when (isa? %audiomixer gst-element)
	 (gst-object-property-set! %audiomixer :volume (/ vol 100))
	 (with-access::musicstatus %status (volume)
	    (set! volume vol)))))

;*=====================================================================*/
;*    .../prgm/project/bigloo/api/mpg123/examples/musicplay.scm        */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Jun 26 07:30:16 2011                          */
;*    Last change :  Wed Jul 13 05:48:28 2011 (serrano)                */
;*    Copyright   :  2011 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    A multimedia MUSIC player built on top of MPG123 and ALSA.       */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module musicplay
   (library multimedia pthread alsa mpg123)
   (static (class mpg123decoder::alsadecoder-host
	      (mpg123::mpg123-handle read-only (default (instantiate::mpg123-handle)))))
   (main main))

;*---------------------------------------------------------------------*/
;*    alsadecoder-close ::mpg123decoder ...                            */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-close o::mpg123decoder)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-handle-close mpg123)))

;*---------------------------------------------------------------------*/
;*    alsadecoder-reset! ::mpg123decoder ...                           */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-reset! o::mpg123decoder)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-handle-reset! mpg123)))

;*---------------------------------------------------------------------*/
;*    alsadecoder-host-decode-buffer ::mpg123-decoder ...              */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-host-decode-buffer o::mpg123decoder inbuf inoff insz outbuf)
   (with-access::mpg123decoder o (mpg123)
      (multiple-value-bind (status size)
	 (mpg123-decode mpg123 inbuf inoff insz outbuf (string-length outbuf))
	 (if (eq? status 'new-format)
	     (multiple-value-bind (rate channels encoding)
		(mpg123-get-format mpg123)
		(values status size rate channels encoding))
	     (values status size #f #f #f)))))

;*---------------------------------------------------------------------*/
;*    alsadecoder-position ::mpg123decoder ...                         */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-position o::mpg123decoder buf)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-position mpg123 buf)))

;*---------------------------------------------------------------------*/
;*    alsadecoder-info ::mpg123decoder ...                             */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-info o::mpg123decoder)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-info mpg123)))

;*---------------------------------------------------------------------*/
;*    alsadecoder-volume-set! ::mpg123decoder ...                      */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-volume-set! o::mpg123decoder vol)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-volume-set! mpg123 vol)))

;*---------------------------------------------------------------------*/
;*    alsadecoder-seek ::mpg123decoder ...                             */
;*---------------------------------------------------------------------*/
(define-method (alsadecoder-seek o::mpg123decoder ms)
   (with-access::mpg123decoder o (mpg123)
      (mpg123-seek mpg123 ms)))

;*---------------------------------------------------------------------*/
;*    directory->files ...                                             */
;*---------------------------------------------------------------------*/
(define (directory->files path)
   (cond
      ((directory? path)
       (append-map (lambda (p)
		      (directory->files (make-file-name path p)))
	  (sort (lambda (s1 s2)
		   (>fx (string-natural-compare3 s1 s2) 0))
	     (reverse (directory->list path)))))
      ((string-suffix? ".m3u" path)
       (filter-map (lambda (p)
		      (let ((path (car p)))
			 (with-handler
			    (lambda (e) #f)
			    (call-with-input-file path (lambda (ip) path)))))
	  (reverse (call-with-input-file path read-m3u))))
      (else
       (list path))))

;*---------------------------------------------------------------------*/
;*    main ...                                                         */
;*---------------------------------------------------------------------*/
(define (main args)
   
   (let ((files '())
	 (volume 80)
	 (device "plughw:0,0"))
      
      (args-parse (cdr args)
	 ((("-h" "--help") (help "This message"))
	  (print "musicplay")
	  (print "usage: musicplay [options] file1 file2 ...")
	  (newline)
	  (args-parse-usage #f)
	  (exit 0))
	 ((("-v" "--volume") ?vol (help "Set volume"))
	  (set! volume (string->integer vol)))
	 ((("-d" "--device") ?dev (help "Select device"))
	  (set! device dev))
	 (else
	  (set! files (append (directory->files else) files))))

      (when (pair? files)
	 (let* ((pcm (instantiate::alsa-snd-pcm
			(device device)))
		(decoder (instantiate::mpg123decoder
			    (mimetypes '("audio/mpeg"))))
		(player (instantiate::alsamusic
			   (decoders (list decoder))
			   (mkthread (lambda (b) (instantiate::pthread (body b))))
			   (pcm pcm))))
	    (music-volume-set! player volume)
	    (music-playlist-clear! player)
	    (print "playing: ")
	    (for-each (lambda (p)
			 (print "  " p)
			 (music-playlist-add! player p))
	       (reverse files))
	    (music-play player)
	    (music-event-loop player
	       :frequency 20000
	       :onstate (lambda (status)
			   (with-access::musicstatus status (state song volume
							       songpos
							       songlength)
			      (print "state: " state)
			      (case state
				 ((play)
				  (print "song: " (list-ref (music-playlist-get player)  song)
				     " [" songpos "/" songlength "]"))
				 ((ended)
				  (newline)
				  (when (=fx song (-fx (length files) 1))
				     (exit 0))))))
	       :onmeta (lambda (meta)
			  (print "meta: " meta)
			  (print "playlist: " (length (music-playlist-get player))))
	       :onerror (lambda (err)
			   (print "error: " err))
	       :onvolume (lambda (volume)
			    (print "volume: " volume)))))))

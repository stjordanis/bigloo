;*=====================================================================*/
;*    serrano/prgm/project/bigloo/api/multimedia/src/Llib/id3.scm      */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano & John G. Malecki                  */
;*    Creation    :  Sun Jul 10 16:21:17 2005                          */
;*    Last change :  Tue Nov 15 18:22:04 2011 (serrano)                */
;*    Copyright   :  2005-11 Manuel Serrano and 2009 John G Malecki    */
;*    -------------------------------------------------------------    */
;*    MP3 ID3 tags and Vorbis tags                                     */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __multimedia-id3

   (import __multimedia-mp3)
   
   (static (class &large-frame-exception::&exception
	      (size::elong read-only)))
	   
   (export (abstract-class musictag
	      (title::bstring read-only)
	      (artist::bstring read-only)
	      (interpret::obj read-only (default #f))
	      (album::bstring read-only)
	      (track::int (default 0))
	      (year::int read-only)
	      (genre::bstring read-only)
	      (comment::bstring read-only)
	      (ufid::obj read-only (default #unspecified))
	      (copyright::obj read-only (default #f))
	      (picture::obj (default #f)))

	   (class vorbis::musictag)
	   
	   (class id3::musictag
	      version::bstring
	      (orchestra::obj read-only (default #f))
	      (conductor::obj read-only (default #f))
	      (recording read-only (default #f))
	      (cd::obj (default #f))
	      (woaf::obj (default #f))
	      (woar::obj (default #f))
	      (wors::obj (default #f)))

	   (class musicinfo
	      (format::bstring read-only)
	      (samplerate::long read-only)
	      (channels::int read-only)
	      (bps::int read-only)
	      (duration::long read-only))

	   (mp3-id3 ::bstring)
	   (mp3-musictag ::bstring)
	   (ogg-musictag ::bstring)
	   (flac-musictag ::bstring)
	   (file-musictag ::bstring)
	   (flac-musicinfo ::bstring)
	   (mp3-musicinfo ::bstring)
	   (file-musicinfo ::bstring)))

;*---------------------------------------------------------------------*/
;*    *id3v2-genres* ...                                               */
;*---------------------------------------------------------------------*/
(define *id3v2-genres*
   '#("Blues"
      "Classic Rock"
      "Country"
      "Dance"
      "Disco"
      "Funk"
      "Grunge"
      "Hip-Hop"
      "Jazz"
      "Metal"
      "New Age"
      "Oldies"
      "Other"
      "Pop"
      "R&B"
      "Rap"
      "Reggae"
      "Rock"
      "Techno"
      "Industrial"
      "Alternative"
      "Ska"
      "Death Metal"
      "Pranks"
      "Soundtrack"
      "Euro-Techno"
      "Ambient"
      "Trip-Hop"
      "Vocal"
      "Jazz+Funk"
      "Fusion"
      "Trance"
      "Classical"
      "Instrumental"
      "Acid"
      "House"
      "Game"
      "Sound Clip"
      "Gospel"
      "Noise"
      "AlternRock"
      "Bass"
      "Soul"
      "Punk"
      "Space"
      "Meditative"
      "Instrumental Pop"
      "Instrumental Rock"
      "Ethnic"
      "Gothic"
      "Darkwave"
      "Techno-Industrial"
      "Electronic"
      "Pop-Folk"
      "Eurodance"
      "Dream"
      "Southern Rock"
      "Comedy"
      "Cult"
      "Gangsta"
      "Top 40"
      "Christian Rap"
      "Pop/Funk"
      "Jungle"
      "Native American"
      "Cabaret"
      "New Wave"
      "Psychadelic"
      "Rave"
      "Showtunes"
      "Trailer"
      "Lo-Fi"
      "Tribal"
      "Acid Punk"
      "Acid Jazz"
      "Polka"
      "Retro"
      "Musical"
      "Rock & Roll"
      "Hard Rock"
      "Folk"
      "Folk-Rock"
      "National Folk"
      "Swing"
      "Fast Fusion"
      "Bebob"
      "Latin"
      "Revival"
      "Celtic"
      "Bluegrass"
      "Avantgarde"
      "Gothic Rock"
      "Progressive Rock"
      "Psychedelic Rock"
      "Symphonic Rock"
      "Slow Rock"
      "Big Band"
      "Chorus"
      "Easy Listening"
      "Acoustic"
      "Humour"
      "Speech"
      "Chanson"
      "Opera"
      "Chamber Music"
      "Sonata"
      "Symphony"
      "Booty Bass"
      "Primus"
      "Porn Groove"
      "Satire"
      "Slow Jam"
      "Club"
      "Tango"
      "Samba"
      "Folklore"
      "Ballad"
      "Power Ballad"
      "Rhythmic Soul"
      "Freestyle"
      "Duet"
      "Punk Rock"
      "Drum Solo"
      "Acapella"
      "Euro-House"
      "Dance Hall"))

;*---------------------------------------------------------------------*/
;*    string-cut! ...                                                  */
;*---------------------------------------------------------------------*/
(define (string-cut! s)
   (let ((i (string-index s #a000)))
      (cond
	 ((not i)
	  s)
	 ((=fx i 0)
	  "")
	 (else
	  (string-shrink! s i)))))

;*---------------------------------------------------------------------*/
;*    mmap-substring/len ...                                           */
;*---------------------------------------------------------------------*/
(define-inline (mmap-substring/len mm start::elong len::elong)
   (mmap-substring mm start (+elong start len)))

;*---------------------------------------------------------------------*/
;*    id3v1? ...                                                       */
;*---------------------------------------------------------------------*/
(define (id3v1? mm)
   (and (>elong (mmap-length mm) 128)
	(string=? (mmap-substring/len mm (-elong (mmap-length mm) 128) #e3)
		  "TAG")))

;*---------------------------------------------------------------------*/
;*    id3v1.1? ...                                                     */
;*---------------------------------------------------------------------*/
(define (id3v1.1? mm)
   (and (id3v1? mm)
	(char=? (mmap-ref mm (-elong (mmap-length mm) #e3)) #a000)
	(not (char=? (mmap-ref mm (-elong (mmap-length mm) #e2)) #a000))))

;*---------------------------------------------------------------------*/
;*    mp3-id3v1 ...                                                    */
;*---------------------------------------------------------------------*/
(define (mp3-id3v1 mm)
   (instantiate::id3
      (version "id3v1")
      (title (string-cut! (mmap-substring/len mm (-elong (mmap-length mm) #e125) #e30)))
      (artist (string-cut! (mmap-substring/len mm (-elong (mmap-length mm) #e95) #e30)))
      (album (string-cut! (mmap-substring/len mm (-elong (mmap-length mm) #e65) #e30)))
      (year (string->integer (mmap-substring/len mm (-elong (mmap-length mm) #e35) #e4)))
      (comment (string-cut! (mmap-substring/len mm (-elong (mmap-length mm) #e31) #e4)))
      (genre (case (mmap-ref mm (-elong (mmap-length mm) #e1))
		(else "unknown")))))

;*---------------------------------------------------------------------*/
;*    mp3-id3v11 ...                                                   */
;*---------------------------------------------------------------------*/
(define (mp3-id3v11 mm)
   (let ((id (mp3-id3v1 mm)))
      (with-access::id3 id (version track)
	 (set! version "id3v1.1")
	 (set! track (char->integer (mmap-ref mm (-elong (mmap-length mm) #e2))))
	 id)))

;*---------------------------------------------------------------------*/
;*    id3v2.2? ...                                                     */
;*---------------------------------------------------------------------*/
(define (id3v2.2? mm)
   (and (>elong (mmap-length mm) #e3)
	(string=? (mmap-substring/len mm #e0 #e5) "ID3\002\000")))

;*---------------------------------------------------------------------*/
;*    id3v2.3? ...                                                     */
;*---------------------------------------------------------------------*/
(define (id3v2.3? mm)
   (and (>elong (mmap-length mm) 3)
	(string=? (mmap-substring/len mm #e0 #e5) "ID3\003\000")))

;*---------------------------------------------------------------------*/
;*    id3v2.4? ...                                                     */
;*---------------------------------------------------------------------*/
(define (id3v2.4? mm)
   (and (>elong (mmap-length mm) 3)
	(string=? (mmap-substring/len mm #e0 #e5) "ID3\004\000")))

;*---------------------------------------------------------------------*/
;*    id3v2-size ...                                                   */
;*---------------------------------------------------------------------*/
(define (id3v2-size mm o::elong)
   (let ((n0 (char->integer (mmap-ref mm o)))
	 (n1 (char->integer (mmap-ref mm (+elong #e1 o))))
	 (n2 (char->integer (mmap-ref mm (+elong #e2 o))))
	 (n3 (char->integer (mmap-ref mm (+elong #e3 o)))))
      (fixnum->elong
       (+fx (bit-lsh n0 (*fx 3 7))
	    (+fx (bit-lsh n1 (*fx 2 7))
		 (+fx (bit-lsh n2 7)
		      n3))))))

;*---------------------------------------------------------------------*/
;*    get-ucs2-string ...                                              */
;*---------------------------------------------------------------------*/
(define (get-ucs2-string mm o::elong sz::elong)
   ;; get the bom
   (let* ((n0 (char->integer (mmap-ref mm o)))
	  (n1 (char->integer (mmap-ref mm (+ o 1))))
	  (sz (/fx sz 2))
	  (len (- sz 1))
	  (res (make-ucs2-string (elong->fixnum len))))
      ;; debug
      [assert (n0 n1) (or (and (=fx n0 #xfe) (=fx n1 #xff)
			       (and (=fx n0 #xff) (=fx n1 #xfe))))]
      (if (and (=fx n0 #xfe) (=fx n1 #xff))
	  ;; big-endian
	  (let loop ((i 0)
		     (j::elong (+ o 2)))
	     (if (= i len)
		 res
		 (let* ((u0 (char->integer (mmap-ref mm j)))
			(u1 (char->integer (mmap-ref mm (+ j 1))))
			(u (+fx (bit-lsh u0 8) u1)))
		    (ucs2-string-set! res i (integer->ucs2 u))
		    (loop (+ i 1) (+ j 2)))))
	  ;; little-endian
	  (let loop ((i 0)
		     (j (+ o 2)))
	     (if (= i len)
		 res
		 (let* ((u0 (char->integer (mmap-ref mm j)))
			(u1 (char->integer (mmap-ref mm (+ j 1))))
			(u (+fx (bit-lsh u1 8) u0)))
		    (ucs2-string-set! res i (integer->ucs2 u))
		    (loop (+ i 1) (+ j 2))))))))

;*---------------------------------------------------------------------*/
;*    get-utf16-be-string ...                                          */
;*    -------------------------------------------------------------    */
;*    This assumes an UCS-2 string.                                    */
;*---------------------------------------------------------------------*/
(define (get-utf16-be-string mm o::elong len::elong)
   (let* ((sz (/fx len 2))
	  (res (make-ucs2-string (elong->fixnum sz))))
      (let loop ((i 0)
		 (j::elong o))
	 (if (= i len)
	     res
	     (let* ((u0 (char->integer (mmap-ref mm j)))
		    (u1 (char->integer (mmap-ref mm (+ j 1))))
		    (u (+fx (bit-lsh u0 8) u1)))
		(ucs2-string-set! res i (integer->ucs2 u))
		(loop (+ i 1) (+ j 2)))))))

;*---------------------------------------------------------------------*/
;*    id3v2-get-string ...                                             */
;*---------------------------------------------------------------------*/
(define (id3v2-get-string mm o::elong sz::elong)
   (if (= sz 1)
       ""
       (case (mmap-ref mm o)
	  ((#a000)
	   ;; an ISO 8859-1 string
	   (iso-latin->utf8! (mmap-substring/len mm (+ o 1) (- sz 1))))
	  ((#a001)
	   ;; an UCS2 string
	   (ucs2-string->utf8-string (get-ucs2-string mm (+ o 1) (- sz 1))))
	  ((#a002)
	   ;; UTF-16BE without BOM
	   (ucs2-string->utf8-string (get-utf16-be-string mm (+ o 1) (- sz 1))))
	  ((#a003)
	   ;; an utf-8 string
	   (mmap-substring/len mm (+ o 1) (- sz 1)))
	  (else
	   ;; fallback
	   (mmap-substring/len mm (+ o 1) (- sz 1))))))
 
;*---------------------------------------------------------------------*/
;*    id3v2.2-frame ...                                                */
;*---------------------------------------------------------------------*/
(define (id3v2.2-frame mm o::elong)
   (let ((n0 (char->integer (mmap-ref mm (+ o 3))))
	 (n1 (char->integer (mmap-ref mm (+ o 4))))
	 (n2 (char->integer (mmap-ref mm (+ o 5)))))
      (values (mmap-substring/len mm o #e3)
	      (fixnum->elong
	       (+fx (bit-lsh n0 (*fx 2 7))
		    (+fx (bit-lsh n1 7)
			 n2))))))

;*---------------------------------------------------------------------*/
;*    id3v2.2-frames ...                                               */
;*---------------------------------------------------------------------*/
(define (id3v2.2-frames mm)
   (let* ((size (id3v2-size mm #e6))
	  (end (+ #e11 size))
	  (flags (mmap-ref mm #e4)))
      (let loop ((i #e10)
		 (frames '()))
	 (if (>=elong i end)
	     frames
	     (multiple-value-bind (id sz flag)
		(id3v2.2-frame mm i)
		(if (or (=elong sz #e0) (>elong (+elong i sz) end))
		    frames
		    (case (string-ref id 0)
		       ((#\T #\A #\W)
			(loop (+elong i (+elong sz 6))
			      (cons (cons id (id3v2-get-string mm (+ i 6) sz))
				    frames)))
		       (else
			(loop (+elong i (+elong sz 6)) frames)))))))))
      
;*---------------------------------------------------------------------*/
;*    id3v2.3-frame ...                                                */
;*---------------------------------------------------------------------*/
(define (id3v2.3-frame mm o::elong)
   (let* ((n0 (char->integer (mmap-ref mm (+ o 4))))
	  (n1 (char->integer (mmap-ref mm (+ o 5))))
	  (n2 (char->integer (mmap-ref mm (+ o 6))))
	  (n3 (char->integer (mmap-ref mm (+ o 7)))))
      (values (mmap-substring/len mm o #e4)
	      (fixnum->elong
	       (+fx (bit-lsh n0 (*fx 3 7))
		    (+fx (bit-lsh n1 (*fx 2 7))
			 (+fx (bit-lsh n2 7)
			      n3))))
	      (mmap-substring/len mm (+ o 8) #e2))))

;*---------------------------------------------------------------------*/
;*    id3v2.3-frames ...                                               */
;*---------------------------------------------------------------------*/
(define (id3v2.3-frames mm)
   (let* ((size (id3v2-size mm #e6))
	  (end (+ 11 size))
	  (flags (mmap-ref mm #e4)))
      (if (> size (mmap-length mm))
	  (raise
	   (instantiate::&large-frame-exception
	      (fname "id3.scm")
	      (size size)))
	  (let loop ((i #e10)
		     (frames '()))
	     (if (>= i end)
		 frames
		 (multiple-value-bind (id sz flag)
		    (id3v2.3-frame mm i)
		    (if (or (= sz 0) (> (+ i sz) end))
			frames
			(case (string-ref id 0)
			   ((#\T #\A #\W)
			    (loop (+ i (+ sz 10))
				  (cons (cons id (id3v2-get-string mm (+ i 10) sz))
					frames)))
			   (else
			    (loop (+ i (+ sz 10)) frames))))))))))

;*---------------------------------------------------------------------*/
;*    id3v2.4-frames ...                                               */
;*---------------------------------------------------------------------*/
(define (id3v2.4-frames mm)
   (id3v2.3-frames mm))

;*---------------------------------------------------------------------*/
;*    id3v2-get-frame ...                                              */
;*---------------------------------------------------------------------*/
(define (id3v2-get-frame key frames default)
   (let ((f (assoc key frames)))
      (if (pair? f)
	  (cdr f)
	  default)))

;*---------------------------------------------------------------------*/
;*    mp3-id3v2.2 ...                                                  */
;*---------------------------------------------------------------------*/
(define (mp3-id3v2.2 mm)
   (let ((frames (id3v2.2-frames mm)))
      (instantiate::id3
	 (version "id3v2.3")
	 (title (id3v2-get-frame "TT1" frames "???"))
	 (artist (id3v2-get-frame "TPE1" frames "???"))
	 (orchestra (id3v2-get-frame "TP2" frames #f))
	 (conductor (id3v2-get-frame "TP3" frames #f))
	 (interpret (id3v2-get-frame "TP4" frames #f))
	 (album (id3v2-get-frame "TAL" frames "???"))
	 (year (string->integer (id3v2-get-frame "TYE" frames "-1")))
	 (recording (id3v2-get-frame "TRD" frames #f))
	 (comment (id3v2-get-frame "COM" frames ""))
	 (genre (id3v2-genre (id3v2-get-frame "TCO" frames "-")))
	 (track (string->integer (id3v2-get-frame "TRK" frames "-1")))
	 (cd (id3v2-get-frame "MCI" frames #f)))))

;*---------------------------------------------------------------------*/
;*    id3v2-genre ...                                                  */
;*---------------------------------------------------------------------*/
(define (id3v2-genre str)
   (if (string=? str "")
       "unknown"
       (string-case str
	  ((: "(" (+ digit) ")")
	   (let ((n (string->integer (the-substring 1 -1))))
	      (cond
		 ((<fx n 0)
		  "unknown")
		 ((>=fx n (vector-length *id3v2-genres*))
		  "unknown")
		 (else
		  (vector-ref *id3v2-genres* n)))))
	  (else "unknown"))))

;*---------------------------------------------------------------------*/
;*    id3v2-picture ...                                                */
;*---------------------------------------------------------------------*/
(define (id3v2-picture frame)
   (when (string? frame)
      (let ((i (string-index frame #a000)))
	 (when i
	    (let ((mime-type (if (=fx i 0) "image/" (substring frame 0 i)))
		  (j (string-index frame  #a000 (+fx i 2))))
	       (when j
		  (let ((descr (substring frame (+fx i 1) j))
			(data (substring frame (+fx j 1))))
		     (list mime-type descr data))))))))
   
;*---------------------------------------------------------------------*/
;*    mp3-id3v2.3 ...                                                  */
;*---------------------------------------------------------------------*/
(define (mp3-id3v2.3 mm)
   (let ((frames (id3v2.3-frames mm)))
      (instantiate::id3
	 (version "id3v2.3")
	 (title (id3v2-get-frame "TIT2" frames "???"))
	 (artist (id3v2-get-frame "TPE1" frames "???"))
	 (orchestra (id3v2-get-frame "TPE2" frames #f))
	 (conductor (id3v2-get-frame "TPE3" frames #f))
	 (interpret (id3v2-get-frame "TPE4" frames #f))
	 (album (id3v2-get-frame "TALB" frames "???"))
	 (year (string->integer (id3v2-get-frame "TYER" frames "-1")))
	 (recording (id3v2-get-frame "TRDA" frames #f))
	 (comment (id3v2-get-frame "COMM" frames ""))
	 (genre (id3v2-genre (id3v2-get-frame "TCON" frames "-")))
	 (track (string->integer (id3v2-get-frame "TRCK" frames "-1")))
	 (cd (id3v2-get-frame "MCDI" frames #f))
	 (ufid (id3v2-get-frame "UFID" frames #f))
	 (copyright (id3v2-get-frame "TCOP" frames #f))
	 (picture (id3v2-picture (id3v2-get-frame "APIC" frames #f)))
	 (woaf (id3v2-get-frame "WOAF" frames #f))
	 (woar (id3v2-get-frame "WOAR" frames #f))
	 (wors (id3v2-get-frame "WORS" frames #f)))))

;*---------------------------------------------------------------------*/
;*    mp3-id3v2.4 ...                                                  */
;*---------------------------------------------------------------------*/
(define (mp3-id3v2.4 mm)
   (let ((frames (id3v2.4-frames mm)))
      (instantiate::id3
	 (version "id3v2.4")
	 (title (id3v2-get-frame "TIT2" frames "???"))
	 (artist (id3v2-get-frame "TPE1" frames "???"))
	 (orchestra (id3v2-get-frame "TPE2" frames #f))
	 (conductor (id3v2-get-frame "TPE3" frames #f))
	 (interpret (id3v2-get-frame "TPE4" frames #f))
	 (album (id3v2-get-frame "TALB" frames "???"))
	 (year (string->integer (id3v2-get-frame "TDRC" frames "-1")))
	 (recording (id3v2-get-frame "TORY" frames #f))
	 (comment (id3v2-get-frame "COMM" frames ""))
	 (genre (id3v2-genre (id3v2-get-frame "TCON" frames "-")))
	 (track (string->integer (id3v2-get-frame "TRCK" frames "-1")))
	 (cd (id3v2-get-frame "MCDI" frames #f))
	 (ufid (id3v2-get-frame "UFID" frames #f))
	 (copyright (id3v2-get-frame "TCOP" frames #f))
	 (picture (id3v2-picture (id3v2-get-frame "APIC" frames #f)))
	 (woaf (id3v2-get-frame "WOAF" frames #f))
	 (woar (id3v2-get-frame "WOAR" frames #f))
	 (wors (id3v2-get-frame "WORS" frames #f)))))

;*---------------------------------------------------------------------*/
;*    mp3-id3 ...                                                      */
;*---------------------------------------------------------------------*/
(define (mp3-id3 path)
   (mp3-musictag path))

;*---------------------------------------------------------------------*/
;*    mp3-musictag ...                                                 */
;*---------------------------------------------------------------------*/
(define (mp3-musictag path)
   (if (not (file-exists? path))
       (error/errno $errno-io-file-not-found-error
	  "mp3-musictag" "Can't find file" path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (cond
		((id3v2.4? mm) (mp3-id3v2.4 mm))
		((id3v2.3? mm) (mp3-id3v2.3 mm))
		((id3v2.2? mm) (mp3-id3v2.2 mm))
		((id3v1.1? mm) (mp3-id3v11 mm))
		((id3v1? mm) (mp3-id3v1 mm))
		(else #f))
	     (close-mmap mm)))))

;*---------------------------------------------------------------------*/
;*    neq-input-string ...                                             */
;*---------------------------------------------------------------------*/
(define (neq-input-string mm s)
   ;; Consume matching input. Stop immediately upon mismatch.
   (if (<fx (-fx (mmap-length mm) (mmap-read-position mm)) (string-length s))
       #t
       (let loop ((i 0))
	  (if (=fx i (string-length s))
	      #f
	      (if (char=? (mmap-get-char mm) (string-ref s i))
		  (loop (+fx 1 i))
		  #t)))))

;*---------------------------------------------------------------------*/
;*    ubigendian2 ...                                                  */
;*---------------------------------------------------------------------*/
(define (ubigendian2 mm)
   ;; read an unsigned 3 bytes big-endian integer
   (let* ((n0 (char->integer (mmap-get-char mm)))
	  (n1 (char->integer (mmap-get-char mm))))
      (fixnum->elong (+fx (bit-lsh n0 8) n1))))

;*---------------------------------------------------------------------*/
;*    ubigendian3 ...                                                  */
;*---------------------------------------------------------------------*/
(define (ubigendian3 mm)
   ;; read an unsigned 3 bytes big-endian integer
   (let* ((n0 (char->integer (mmap-get-char mm)))
	  (n1 (char->integer (mmap-get-char mm)))
	  (n2 (char->integer (mmap-get-char mm))))
      (fixnum->elong
       (+fx (bit-lsh n0 (*fx 2 8))
	    (+fx (bit-lsh n1 8)
		 n2)))))

;*---------------------------------------------------------------------*/
;*    ubigendian4 ...                                                  */
;*---------------------------------------------------------------------*/
(define (ubigendian4 mm)
   ;; read an unsigned 4 bytes big-endian integer
   (let* ((n0 (char->integer (mmap-get-char mm)))
	  (n1 (char->integer (mmap-get-char mm)))
	  (n2 (char->integer (mmap-get-char mm)))
	  (n3 (char->integer (mmap-get-char mm))))
      (+llong (bit-lshllong n0 (*fx 3 8))
	 (+llong (bit-lshllong n1 (*fx 2 8))
	    (+llong (bit-lshllong n2 (*fx 1 8))
	       (fixnum->llong n3))))))

;*---------------------------------------------------------------------*/
;*    utillendian4 ...                                                 */
;*---------------------------------------------------------------------*/
(define (ulittlendian4 mm)
   ;; read an unsigned 4 byte little-endian integer
   (let* ((n0 (char->integer (mmap-get-char mm)))
	  (n1 (char->integer (mmap-get-char mm)))
	  (n2 (char->integer (mmap-get-char mm)))
	  (n3 (char->integer (mmap-get-char mm))))
      (fixnum->elong
       (+fx (bit-lsh n3 (*fx 3 8))
	    (+fx (bit-lsh n2 (*fx 2 8))
		 (+fx (bit-lsh n1 8)
		      n0))))))

;*---------------------------------------------------------------------*/
;*    split-comment ...                                                */
;*---------------------------------------------------------------------*/
(define (split-comment c)
   ;; vorbis comments always look like "foo=bar"
   ;; split at the = and return the pair (foo . bar)
   ;; foo is symbolized.
   ;; bar ought to be symbolized to reduce space but that optimization was lost in the translation
   (let ((i (string-index c "=")))
      (cons (string->symbol (string-downcase! (substring c 0 i)))
	    (substring c (+fx 1 i) (string-length c)))))

;*---------------------------------------------------------------------*/
;*    ogg-comments->musictag ...                                       */
;*---------------------------------------------------------------------*/
(define (ogg-comments->musictag lst)
   
   (define (get key lst def)
      (let ((c (assq key lst)))
	 (if (pair? c)
	     (cdr c)
	     def)))

   (when (pair? lst)
      (instantiate::vorbis
	 (title (get 'title lst "unknown"))
	 (artist (get 'artist lst "unknown"))
	 (interpret (get 'performer lst "unknown"))
	 (album (get 'album lst "unknown"))
	 (year (string->integer (get 'date lst "0")))
	 (genre (get 'genre lst "Other"))
	 (track (string->integer (get 'tracknumber lst "0")))
	 (comment (get 'description lst "")))))

;*---------------------------------------------------------------------*/
;*    parse-metadata-block-vorbis-comment-body ...                     */
;*---------------------------------------------------------------------*/
(define (parse-metadata-block-vorbis-comment-body mm i comments)
   (if (zeroelong? i)
       (reverse! comments)
       (let* ((comment-length (ulittlendian4 mm))
	      ;; we really should check that comment-length is not too big.
	      ;; does bigloo have a maximum string length?
	      (comment-string (mmap-substring mm (mmap-read-position mm) (+fx comment-length (mmap-read-position mm))))
	      (comment (split-comment comment-string)))
	  (parse-metadata-block-vorbis-comment-body mm (-elong i 1) (cons comment comments)))))

;*---------------------------------------------------------------------*/
;*    parse-metadata-block-vorbis-comment ...                          */
;*---------------------------------------------------------------------*/
(define (parse-metadata-block-vorbis-comment mm)
   (let* ((vendor-length (ulittlendian4 mm))
	  ;; we really should check that this length is not too big.
	  (vendor-string (mmap-substring mm (mmap-read-position mm) (+fx vendor-length (mmap-read-position mm))))
	  (user-comment-list-length (ulittlendian4 mm))
	  (- (assert (user-comment-list-length) (<=fx user-comment-list-length 100)))) ;; 100 is an arbitrary limit
      (parse-metadata-block-vorbis-comment-body mm user-comment-list-length `((vendor-string . ,vendor-string)))))

;*---------------------------------------------------------------------*/
;*    read-ogg-comments ...                                            */
;*    -------------------------------------------------------------    */
;*    The Vorbis web page is                                           */
;*      http://www.xiph.org/vorbis/                                    */
;*    The specification this program uses is                           */
;*      http://www.xiph.org/vorbis/doc/Vorbis_I_spec.html              */
;*---------------------------------------------------------------------*/
(define (read-ogg-comments path mm)
   
   (define (err msg)
      (raise (instantiate::&io-parse-error
		(proc 'read-ogg-comment)
		(msg msg)
		(obj path))))
   
   (define (local-read-ogg-comments path mm)
      (unless (neq-input-string mm "OggS")
	 (unless (char=? #a000 (mmap-get-char mm))
	    (err "invalid OggS page0"))
	 (mmap-read-position-set! mm (+fx 21 (mmap-read-position mm)))
	 (let ((ps (char->integer (mmap-get-char mm))))
	    ;; ps should be 0 .. 511 and not negative.  is the correct?
	    (mmap-read-position-set! mm (+fx ps (mmap-read-position mm)))
	    (let ((packet-type (mmap-get-char mm)))
	       (when (neq-input-string mm "vorbis")
		  (err "invalid ogg vorbis identification"))
	       (case packet-type
		  ((#a001)
		   (mmap-read-position-set! mm (+fx 23 (mmap-read-position mm)))
		   (local-read-ogg-comments path mm))
		  ((#a003)
		   (parse-metadata-block-vorbis-comment mm))
		  (else
		   (err "invalid ogg vorbis common header")))))))
   
   (mmap-read-position-set! mm #e0)
   (local-read-ogg-comments path mm))

;*---------------------------------------------------------------------*/
;*    read-flac-comments ...                                           */
;*    -------------------------------------------------------------    */
;*    Information on flac can be found at                              */
;*       http://flac.sourceforge.net/format.html                       */
;*    Note that all flac numbers are big-endian.                       */
;*    All vorbis numbers are little-endian.                            */
;*    (As a reminder, little-endian means digit N is worth R**N.)      */
;*---------------------------------------------------------------------*/
(define (read-flac-comments mm)
   
   (define block4s '())
   
   (define (parse-metadata-block-data block-type block-length)
      (if (=fx (bit-and block-type #x7F) 4)
	  (let ((comments (parse-metadata-block-vorbis-comment mm)))
	     (set! block4s (append! comments block4s)))
	  (mmap-read-position-set! mm (+fx block-length (mmap-read-position mm))))
      (let ((block-is-last (not (zerofx? (bit-and block-type #x80)))))
	 (if block-is-last
	     block4s
	     (parse-metadata-block-headers))))
   
   (define (parse-metadata-block-headers)
      (let* ((block-type (char->integer (mmap-get-char mm)))
	     (block-length (ubigendian3 mm)))
	 (parse-metadata-block-data block-type block-length)))
   
   (mmap-read-position-set! mm #e0)
   
   (unless (neq-input-string mm "fLaC")
      (parse-metadata-block-headers)))

;*---------------------------------------------------------------------*/
;*    flac-musictag ...                                                */
;*---------------------------------------------------------------------*/
(define (flac-musictag path)
   (if (not (file-exists? path))
       (error/errno $errno-io-file-not-found-error
	  "flac-musictag" "Can't find file" path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (ogg-comments->musictag (read-flac-comments mm))
	     (close-mmap mm)))))

;*---------------------------------------------------------------------*/
;*    ogg-musictag ...                                                 */
;*---------------------------------------------------------------------*/
(define (ogg-musictag path)
   (if (not (file-exists? path))
       (error/errno $errno-io-file-not-found-error
	  "ogg-vorbis" "Can't find file" path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (ogg-comments->musictag (read-ogg-comments path mm))
	     (close-mmap mm)))))

;*---------------------------------------------------------------------*/
;*    file-musictag ...                                                */
;*---------------------------------------------------------------------*/
(define (file-musictag path)
   
   (define (mmap-musictag mm)
      (cond
	 ((id3v2.4? mm) (mp3-id3v2.4 mm))
	 ((id3v2.3? mm) (mp3-id3v2.3 mm))
	 ((id3v2.2? mm) (mp3-id3v2.2 mm))
	 ((id3v1.1? mm) (mp3-id3v11 mm))
	 ((id3v1? mm) (mp3-id3v1 mm))
	 ((read-flac-comments mm) => ogg-comments->musictag)
	 ((read-ogg-comments path mm) => ogg-comments->musictag)
	 (else #f)))
   
   (cond
      ((file-exists? path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (mmap-musictag mm)
	     (close-mmap mm))))
      ((open-input-file path)
       =>
       (lambda (p)
	  (unwind-protect
	     (let loop ((s (read-chars 8192 p)))
		;; reads the first 8KB and tries to find a tag
		(let ((mm (string->mmap s)))
		   (unwind-protect
		      (with-handler
			 (lambda (e)
			    (if (isa? e &large-frame-exception)
				(with-access::&large-frame-exception e (size)
				   (let ((sz (elong->fixnum
						(- size (string-length s)))))
				      (loop
					 (string-append s (read-chars sz p)))))))
			 (mmap-musictag mm))
		      (close-mmap mm))))
	     (close-input-port p))))
      (else
       (error/errno $errno-io-file-not-found-error
	  "file-musictag" "Can't find file" path))))

;*---------------------------------------------------------------------*/
;*    read-flac-musicinfo ...                                          */
;*---------------------------------------------------------------------*/
(define (read-flac-musicinfo mm)
   
   (define (skip-id3v2-frame mm)
      (let ((size (id3v2-size mm #e6)))
	 (+ 11 size)))
   
   (define (skip-id3-frame mm)
      (cond
	 ((or (id3v2.4? mm) (id3v2.3? mm) (id3v2.2? mm))
	  (-elong (skip-id3v2-frame mm) 1))
	 ((or (id3v1.1? mm) (id3v1? mm))
	  #e128)
	 (else
	  #e0)))
   
   (define (ubigendian20bits mm)
      ;; read an unsigned 3 byte big-endian integer
      (let* ((n0 (char->integer (mmap-get-char mm)))
	     (n1 (char->integer (mmap-get-char mm))))
	 (fixnum->elong (+fx (bit-lsh n1 8) n0))))
   
   (define (parse-metadata-block-streaminfo mm block-length)
      (let* ((minbsz (ubigendian2 mm))
	     (maxbsz (ubigendian2 mm))
	     (minfsz (ubigendian3 mm))
	     (maxfsz (ubigendian3 mm))
	     (char0-1 (ubigendian2 mm))
	     (char2 (char->integer (mmap-get-char mm)))
	     (char3 (char->integer (mmap-get-char mm)))
	     (char4-7 (ubigendian4 mm))
	     (samplerate (+elong (bit-lshelong char0-1 4)
			    (fixnum->elong (bit-rsh char2 4))))
	     (channels (+fx 1 (bit-and (bit-rsh char2 1) 7)))
	     (bps (+fx 1
		     (+fx (bit-lsh (bit-and char2 1) 4)
			(bit-rsh char3 4))))
	     (totalsample (+llong (bit-lshllong
				     (fixnum->llong (bit-and char3 #x0f))
				     32)
			     char4-7)))
	 (instantiate::musicinfo
	    (format "flac")
	    (samplerate samplerate)
	    (channels channels)
	    (bps bps)
	    (duration (llong->fixnum
			 (/llong totalsample (elong->llong samplerate)))))))
   
   (define (parse-metadata-block-headers mm)
      (let* ((block-type (char->integer (mmap-get-char mm)))
	     (block-length (ubigendian3 mm)))
	 (if (=fx (bit-and block-type #x7F) 0)
	     ;; streaminfo is the first block
	     (parse-metadata-block-streaminfo mm block-length)
	     (begin
		(mmap-read-position-set! mm 0)
		#f))))

   (let ((i (skip-id3-frame mm)))
      (mmap-read-position-set! mm i)
      (if (neq-input-string mm "fLaC")
	  (begin
	     (mmap-read-position-set! mm 0)
	     #f)
	  (parse-metadata-block-headers mm))))
   
;*---------------------------------------------------------------------*/
;*    flac-musicinfo ...                                               */
;*---------------------------------------------------------------------*/
(define (flac-musicinfo path)
   (if (not (file-exists? path))
       (error/errno $errno-io-file-not-found-error
	  "flac-musicinfo" "Can't find file" path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (read-flac-musicinfo mm)
	     (close-mmap mm)))))

;*---------------------------------------------------------------------*/
;*    read-mp3-musicinfo ...                                           */
;*---------------------------------------------------------------------*/
(define (read-mp3-musicinfo mm)
   
   (define (mp3frame->musicinfo frame duration)
      (with-access::mp3frame frame (version layer samplerate bitrate channels)
	 (instantiate::musicinfo
	    (format (if (=fx layer 3)
			"mp3"
			(format "mpeg ~a, layer ~a" version layer)))
	    (samplerate samplerate)
	    (bps bitrate)
	    (channels channels)
	    (duration duration))))
   
   (define (mp3frame-same-constant? f1 f2)
      (with-access::mp3frame f1 ((version1 version)
				 (layer1 layer)
				 (crc1 crc)
				 (samplerate1 samplerate))
	 (with-access::mp3frame f2 ((version2 version)
				    (layer2 layer)
				    (crc2 crc)
				    (samplerate2 samplerate))
	    (and (=fl version1 version2)
		 (=fx layer2 layer2)
		 (=fx crc1 crc2)
		 (=fx samplerate1 samplerate2)))))
   
   ;; skip the ID3 frame
   (cond
      ((id3v2.4? mm) (mp3-id3v2.4 mm))
      ((id3v2.3? mm) (mp3-id3v2.3 mm))
      ((id3v2.2? mm) (mp3-id3v2.2 mm))
      (else (mmap-read-position-set! mm 0)))
   
   (let* ((len (mmap-length mm))
	  (i0 (mmap-read-position mm))
	  (f0 (read-mp3-frame mm i0 (instantiate::mp3frame))))
      (when (isa? f0 mp3frame)
	 (with-access::mp3frame f0 (offset length bitrate)
	    (let ((i0 (+elong offset length)))
	       (let loop ((i (+elong 1 i0))
			  (f (instantiate::mp3frame))
			  (c 0))
		  (if (isa? (read-mp3-frame mm i f) mp3frame)
		      (if (mp3frame-same-constant? f f0)
			  (if (=fx c 15)
			      (with-access::mp3frame f (offset length)
				 (loop (+elong offset length) f (-fx c 1)))
			      (let ((nbframes (/fx (-fx len i0) length))
				    (seconds (/fx (-fx len i0) 
						(*fx bitrate 125))))
				 (mp3frame->musicinfo f0 seconds)))
			  (with-access::mp3frame f (duration offset length)
			     (let loop ((i i)
					(d (*fl (fixnum->flonum c) duration)))
				(if (isa? (read-mp3-frame mm i f) mp3frame)
				    (loop (+elong offset length)
				       (+fl d duration))
				    (mp3frame->musicinfo f0
				       (flonum->fixnum (round d))))))))))))))

;*---------------------------------------------------------------------*/
;*    mp3-musicinfo ...                                                */
;*---------------------------------------------------------------------*/
(define (mp3-musicinfo path)
   (if (not (file-exists? path))
       (error/errno $errno-io-file-not-found-error
	  "mp3-musicinfo" "Can't find file" path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (read-mp3-musicinfo mm)
	     (close-mmap mm)))))

;*---------------------------------------------------------------------*/
;*    file-musicinfo ...                                               */
;*---------------------------------------------------------------------*/
(define (file-musicinfo path)
   
   (define (mmap-musicinfo mm)
      (cond
	 ((read-flac-musicinfo mm) => (lambda (mi) mi))
	 ((read-mp3-musicinfo mm) => (lambda (mi) mi))
	 ((read-ogg-comments path mm) #f)
	 (else #f)))
   
   (cond
      ((file-exists? path)
       (let ((mm (open-mmap path :write #f)))
	  (unwind-protect
	     (mmap-musicinfo mm)
	     (close-mmap mm))))
      ((open-input-file path)
       =>
       (lambda (p)
	  (unwind-protect
	     (let loop ((s (read-chars 8192 p)))
		;; reads the first 8KB and tries to find a tag
		(let ((mm (string->mmap s)))
		   (unwind-protect
		      (with-handler
			 (lambda (e)
			    (if (isa? e &large-frame-exception)
				(with-access::&large-frame-exception e (size)
				   (let ((sz (elong->fixnum
						(- size (string-length s)))))
				      (loop (string-append s (read-chars sz p)))))))
			 (mmap-musicinfo mm))
		      (close-mmap mm))))
	     (close-input-port p))))
      (else
       (error/errno $errno-io-file-not-found-error
	  "file-musicinfo" "Can't find file" path))))
   

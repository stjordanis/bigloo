;*=====================================================================*/
;*    serrano/prgm/project/bigloo/comptime/Expand/object.scm           */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri May  3 10:13:58 1996                          */
;*    Last change :  Wed Nov 16 09:41:49 2011 (serrano)                */
;*    Copyright   :  1996-2011 Manuel Serrano, see LICENSE file        */
;*    -------------------------------------------------------------    */
;*    The Object expanders                                             */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module expand_object
   (import  tools_args
	    tools_misc
	    tools_location
	    type_type
	    type_env
	    type_cache
	    expand_eps
	    expand_oldobject
	    engine_param
	    ast_var
	    ast_ident
	    ast_private
	    ast_object
	    ast_node
	    object_class
	    object_slots
	    object_tools
	    object_classgen
	    expand_lambda
	    module_prototype
	    module_module
	    module_class)
   (export  (expand-define-class ::obj ::procedure)
	    (expand-with-access ::obj ::procedure)
	    (expand-instantiate ::obj ::procedure)
	    (expand-co-instantiate ::obj ::procedure)
	    (expand-duplicate ::obj ::procedure)
	    (expand-widen! ::obj ::procedure)
	    (expand-shrink! ::obj ::procedure)))

;*---------------------------------------------------------------------*/
;*    expand-define-class ...                                          */
;*---------------------------------------------------------------------*/
(define (expand-define-class x e)
   (match-case x
      (((or define-class define-final-class define-abstract-class) . ?rest)
       (let* ((nx (evepairify `(class ,@rest) x))
	      (proto (parse-prototype nx)))
	  (if (not proto)
	      (error (car x) "Illegal define-class" x)
	      (begin
		 (declare-class!
		  (cdr proto) *module* 'static
		  (eq? (car x) 'define-final-class)
		  (eq? (car x) 'define-abstract-class) nx #f)
		 (class-finalizer-add-static!)))))
      (else
       (error x "Illegal define-class" x))))
       
;*---------------------------------------------------------------------*/
;*    expand-with-access ...                                           */
;*---------------------------------------------------------------------*/
(define (expand-with-access x e)
   (match-case x
      ((?with-access ?instance (and (? pair?) ?slots) . (and (? pair?) ?body))
       (let* ((loc (find-location x))
	      (class (type-of-id with-access loc)))
	  (cond
	     ((not (tclass? class))
	      (error with-access "Illegal class" x))
	     (else
	      (let loop ((s slots)
			 (nslots '()))
		 (cond
		    ((null? s)
		     (let* ((aux (mark-symbol-non-user! (gensym 'i)))
			    (instance (e instance e))
			    (class-id (type-id class))
			    (taux (make-typed-ident aux class-id)))
			(replace! x
			   (with-lexical
			      (map car nslots) aux (find-location x)
			      (lambda () 
				 (let ((e (internal-begin-expander
					     (with-access-expander
						e aux class nslots x))))
				    `(let ((,taux ,instance))
					,(e (expand-progn body) e))))))))
		    ((not (pair? s))
		     (error s "Illegal field" x))
		    ((symbol? (car s))
		     (loop (cdr s) (cons (list (car s) (car s)) nslots)))
		    ((and (pair? (car s))
			  (symbol? (car (car s)))
			  (pair? (cdr (car s)))
			  (symbol? (cadr (car s)))
			  (null? (cddr (car s))))
		     (loop (cdr s) (cons (car s) nslots)))
		    (else
		     (error (car s) "Illegal form" x))))))))
      (else
       (error "with-access" "Illegal form" x))))

;*---------------------------------------------------------------------*/
;*    with-access-expander ...                                         */
;*---------------------------------------------------------------------*/
(define (with-access-expander olde i class slots form)
   
   (define (id var) (cadr (assq var slots)))
   
   (let ((ids (map car slots)))
      (lambda (x e)
	 (match-case x
	    ((and ?var (? symbol?))
	     (if (and (memq var ids)
		      (let ((cell (assq var (lexical-stack))))
			 (and (pair? cell) (eq? (cdr cell) i))))
		 (let ((slot (find-class-slot class (id var))))
		    (if (not slot)
			(error (id var) "No such field" form)
			(if *class-gen-accessors?*
			    (olde `(,(symbol-append (type-id class) '- (id var)) ,i) olde)
			    (field-access i (id var)))))
		 (olde var olde)))
	    ((set! (and (? symbol?) ?var) ?val)
	     (let ((val (e val e)))
		(if (and (memq var ids)
			 (let ((cell (assq var (lexical-stack))))
			    (and (pair? cell) (eq? (cdr cell) i))))
		    (let ((slot (find-class-slot class (id var))))
		       (if (not slot)
			   (error (id var) "No such field" form)
			   (object-epairify
			      (if *class-gen-accessors?*
				  (olde `(,(symbol-append (type-id class) '- (id var) '-set!) ,i ,val) olde)
				  (let* ((id (field-access i (id var)))
					 (nx `(set! ,id ,val)))
				     (olde nx olde)))
			      x)))
		    (begin
		       (set-car! (cddr x) val)
		       (olde x olde)))))
	    (else
	     (olde x e))))))

;*---------------------------------------------------------------------*/
;*    expand-instantiate ...                                           */
;*---------------------------------------------------------------------*/
(define (expand-instantiate x e)
   (match-case x
      ((?instantiate . ?-)
       (let ((class (type-of-id instantiate (find-location x))))
	  (cond
	     ((not (tclass? class))
	      (error instantiate "Illegal form" x))
	     ((tclass-abstract? class)
	      (error instantiate "Abstract classes can't be instantiated" x))
	     (else
	      (replace! x (instantiate->make x class e))))))
      (else
       (error "instantiate" "Illegal form" x))))

;*---------------------------------------------------------------------*/
;*    instantiate->make ...                                            */
;*---------------------------------------------------------------------*/
(define (instantiate->make x class e)
   (if *class-gen-accessors?*
       (let ((make-name (class-make class)))
	  (instantiate->fill-accessors x
	     class
	     (lambda (largs)
		(if (epair? x)
		    (econs make-name largs (cer x))
		    (cons make-name largs)))
	     e))
       (let ((o (allocate-expr class)))
	  (instantiate->fill-sans (car x) (cdr x) class
	     (tclass-slots class) o x e))))

;*---------------------------------------------------------------------*/
;*    instantiate->fill-sans ...                                       */
;*---------------------------------------------------------------------*/
(define (instantiate->fill-sans op provided class slots init x e)
   
   (define (collect-slot-values slots)
      (let ((vargs (make-vector (length slots))))
	 ;; collect the default values
	 (let loop ((i 0)
		    (slots slots))
	    (when (pair? slots)
	       (let ((s (car slots)))
		  (cond
		     ((slot-default? s)
		      (vector-set! vargs i (cons #t (slot-default-value s))))
		     (else
		      (vector-set! vargs i (cons #f #unspecified))))
		  (loop (+fx i 1) (cdr slots)))))
	 ;; collect the provided values
	 (let loop ((provided provided))
	    (when (pair? provided)
	       (let ((p (car provided)))
		  (match-case p
		     (((and (? symbol?) ?s-name) ?value)
		      ;; plain slot
		      (let ((pval (vector-ref
				     vargs
				     (find-slot-offset slots s-name op p))))
			 (set-car! pval #t)
			 (set-cdr! pval (object-epairify value p))))
		     (else
		      (error op "Illegal argument \"~a\"" x)))
		  (loop (cdr provided)))))
	 ;; build the result
	 (vector->list vargs)))
   
   (let* ((id (type-id class))
	  (new (gensym 'new))
	  (tnew (make-typed-ident new id))
	  (args (collect-slot-values slots)))
      ;; check that there is enough values
      (for-each (lambda (a s)
		   (unless (or (car a) (slot-virtual? s))
		      ;; value missin
		      (error op
			 (format "Missing value for field \"~a\"" (slot-id s))
			 x)))
	 args slots)
      ;; allocate the object and set the fields,
      ;; first the actual fields, second the virtual fields
      `(let ((,tnew ,init))
	  ;; actual fields
	  ,@(filter-map (lambda (slot val)
			   (unless (slot-virtual? slot)
			      (let ((v (e (cdr val) e))
				    (id (slot-id slot)))
				 `(set! ,(field-access new id)
				     ,v))))
	       slots args)
	  ;; constructors
	  ,@(map (lambda (c) (e `(,c ,new) e)) (find-class-constructors class))
	  ;; virtual fields
	  ,@(filter-map (lambda (slot val)
			   (when (and (slot-virtual? slot)
				      (not (slot-read-only? slot))
				      (car val))
			      (let ((v (e (cdr val) e))
				    (id (slot-id slot)))
				 `(set! ,(field-access new id)
				     ,v))))
	       slots args)
	  ;; return the new instance
	  ,new)))
   
;*---------------------------------------------------------------------*/
;*    expand-co-instantiate ...                                        */
;*---------------------------------------------------------------------*/
(define (expand-co-instantiate x e)
   (match-case x
      ((co-instantiate ?bindings . ?body)
       (replace! x (co-instantiate->let bindings body x e)))
      (else
       (error "co-instantiate" "Illegal form" x))))

;*---------------------------------------------------------------------*/
;*    co-instantiate->let ...                                          */
;*---------------------------------------------------------------------*/
(define (co-instantiate->let bindings body x e)
   (if *class-gen-accessors?*
       (co-instantiate->let-accessors bindings body x e)
       (co-instantiate->let-sans bindings body x e)))

;*---------------------------------------------------------------------*/
;*    co-instantiate->let-sans ...                                     */
;*---------------------------------------------------------------------*/
(define (co-instantiate->let-sans bindings body x e)
   
   (define (find-instantiate-class expr bdg loc)
      (match-case expr
	 ((?instantiate . ?body)
	  (let* ((loc (find-location/loc body loc))
		 (id-type (parse-id instantiate loc))
		 (kclass (cdr id-type)))
	     (cond
		((not (eq? (car id-type) 'instantiate))
		 (error instantiate "Illegal binding" bdg))
		((not (tclass? kclass))
		 (error instantiate "Illegal class" bdg))
		((tclass-abstract? kclass)
		 (error instantiate
		    "Abstract classes can't be instantiated"
		    bdg))
		(else
		 kclass))))
	 (else
	  (error "co-instantiate" "Illegal binding" bdg))))
   
   (let ((loc (find-location x))
	 (vars (map (lambda (bdg)
		       (match-case bdg
			  (((and ?var (? symbol?)) ?expr)
			   (let* ((loc (find-location/loc bdg x))
				  (id-type (parse-id var loc))
				  (id (car id-type))
				  (t (cdr id-type))
				  (klass (find-instantiate-class expr bdg loc)))
			      (if (or (eq? t (get-default-type))
				      (eq? t klass))
				  (list id klass expr)
				  (error (car x) "Illegal variable type" bdg))))
			  (else
			   (error (car x) "Illegal binding" bdg))))
		  bindings)))
      `(let ,(map (lambda (var)
		     (let ((id (car var))
			   (klass (cadr var)))
			`(,(make-typed-ident id (type-id klass))
			  ,(allocate-expr klass))))
		vars)
	  ,@(map (lambda (var)
		    (let ((id (car var))
			  (klass (cadr var))
			  (expr (caddr var)))
		       (instantiate->fill-sans (car expr) (cdr expr)
			  klass (tclass-slots klass) id expr e)))
	       vars)
	  ,(e `(begin ,@body) e))))

;*---------------------------------------------------------------------*/
;*    expand-duplicate ...                                             */
;*---------------------------------------------------------------------*/
(define (expand-duplicate x e)
   (match-case x
      ((?duplicate ?dup . ?prov)
       (let* ((id-type (parse-id duplicate (find-location x)))
	      (id (car id-type))
	      (class (cdr id-type)))
	  (cond
	     ((not (tclass? class))
	      (error duplicate (format "Illegal class type \"~a\"" id) x))
	     ((tclass-abstract? class)
	      (error duplicate "Abstract classes can't be duplicated" x))
	     (else
	      (replace! x (duplicate->make class dup prov x e))))))
      (else
       (error "duplicate" "Illegal form" x))))

;*---------------------------------------------------------------------*/
;*    duplicate->make ...                                              */
;*    -------------------------------------------------------------    */
;*    In contrast with instantiate this macro does not check at        */
;*    compile time that all values are provided. All the missing       */
;*    values (the ones not provided explicitly) are picked from        */
;*    the duplicated object (which hence, is supposed to have the      */
;*    proper fields).                                                  */
;*---------------------------------------------------------------------*/
(define (duplicate->make class duplicated provided x e)
   (if *class-gen-accessors?*
       (e (duplicate->make-accessors x class duplicated provided e) e)
       (duplicate->make-sans class duplicated provided x e)))

;*---------------------------------------------------------------------*/
;*    duplicate->make-sans ...                                         */
;*---------------------------------------------------------------------*/
(define (duplicate->make-sans class duplicated provided x e)
   
   (define (collect-slot-values slots dupvar)
      (let ((vargs (make-vector (length slots))))
	 ;; we collect the provided values
	 (let loop ((provided provided))
	    (when (pair? provided)
	       (let ((p (car provided)))
		  (match-case p
		     (((and (? symbol?) ?s-name) ?value)
		      ;; plain slot
		      (let ((i (find-slot-offset slots s-name "duplicate" p)))
			 (vector-set! vargs
			    i
			    (cons #t (object-epairify value p)))))
		     (else
		      (error (car x) "Illegal form" x)))
		  (loop (cdr provided)))))
	 ;; we collect the duplicated values
	 (let loop ((i 0)
		    (slots slots))
	    (when (pair? slots)
	       (let ((value (vector-ref vargs i)))
		  (unless (pair? value)
		     (let ((slot (car slots)))
			;; no value is provided for this object we pick
			;; one from this duplicated object.
			(vector-set! vargs
			   i
			   (cons #t (field-access dupvar (slot-id slot))))))
		  (loop (+fx i 1) (cdr slots)))))
	 ;; build the result
	 (vector->list vargs)))
   
   (let* ((id (type-id class))
	  (slots (tclass-slots class))
	  (new (gensym 'new))
	  (tnew (make-typed-ident new id))
	  (dupvar (mark-symbol-non-user! (gensym 'duplicated)))
	  (tdupvar (make-typed-ident dupvar (type-id class)))
	  (args (collect-slot-values slots dupvar)))
      ;; allocate the object and set the fields,
      ;; first the actual fields, second the virtual fields
      `(let ((,tdupvar ,(e duplicated e))
	     (,tnew ,(allocate-expr class)))
	  ;; actual fields
	  ,@(filter-map (lambda (slot val)
			   (unless (slot-virtual? slot)
			      (let ((v (e (cdr val) e))
				    (id (slot-id slot)))
				 `(set! ,(field-access new id) ,v))))
	       slots args)
	  ;; constructors
	  ,@(map (lambda (c) (e `(,c ,new) e)) (find-class-constructors class))
	  ;; virtual fields
	  ,@(filter-map (lambda (slot val)
			   (when (and (slot-virtual? slot)
				      (not (slot-read-only? slot))
				      (car val))
			      (let ((v (e (cdr val) e))
				    (id (slot-id slot)))
				 `(set! ,(field-access new id) ,v))))
	       slots args)
	  ,new)))

;*---------------------------------------------------------------------*/
;*    allocate-expr ...                                                */
;*---------------------------------------------------------------------*/
(define (allocate-expr class)
   (if (wide-class? class)
       (let ((super (tclass-its-super class)))
	  (classgen-widen-expr
	     class (classgen-allocate-expr super)))
       (classgen-allocate-expr class)))

;*---------------------------------------------------------------------*/
;*    expand-widen! ...                                                */
;*---------------------------------------------------------------------*/
(define (expand-widen! x e)
   (match-case x
      ((?widen! ?obj . ?provided)
       (let ((class (type-of-id widen! (find-location x))))
	  (if (and (tclass? class) (tclass-widening class))
	      (replace! x (e (make-widening x class obj provided e) e))
	      (error widen!
		 (format "Illegal class type \"~a\"" (type-id class))
		 x))))
      (else
       (error "wident!" "Illegal form" x))))

;*---------------------------------------------------------------------*/
;*    make-widening ...                                                */
;*---------------------------------------------------------------------*/
(define (make-widening form class obj provided e)
   (if *class-gen-accessors?*
       (make-widening-accessors form class obj provided e)
       (make-widening-sans form class obj provided e)))

;*---------------------------------------------------------------------*/
;*    make-widening-sans ...                                           */
;*---------------------------------------------------------------------*/
(define (make-widening-sans form class o provided e)
   (let* ((super (tclass-its-super class))
	  (tid (type-id class))
	  (sid (type-id super))
	  (tmp (mark-symbol-non-user! (gensym 'tmp)))
	  (ttmp (make-typed-ident tmp sid))
	  (slots (filter (lambda (s) (eq? (slot-class-owner s) class))
		    (tclass-slots class))))
      `(let ((,ttmp ,(make-private-sexp 'cast sid o)))
	  ,(classgen-widen-expr class tmp)
	  ,(instantiate->fill-sans (car form) (cddr form)
	      class slots (make-private-sexp 'cast tid tmp) form e))))

;*---------------------------------------------------------------------*/
;*    expand-shrink! ...                                               */
;*---------------------------------------------------------------------*/
(define (expand-shrink! x e)
   (match-case x
      (((and ?sym (? symbol?)) ?o)
       (let ((s (parse-id sym (find-location x))))
	  (if (eq? (car s) 'shrink!)
	      (replace! x (make-a-shrink! e o))
	      (error sym "Illegal shrink!" x))))
      (else
       (error "shrink!" "Illegal form" x))))
		 
;*---------------------------------------------------------------------*/
;*    make-a-shrink! ...                                               */
;*---------------------------------------------------------------------*/
(define (make-a-shrink! e o)
   (let ((newo (mark-symbol-non-user! (gensym 'o))))
      (if *unsafe-type*
	  `(let ((,newo ,(e o e)))
	      ((@ object-class-num-set! __object)
	       ,newo
	       ((@ class-num __object)
		((@ class-super __object)
		 ((@ object-class __object) ,newo))))
	      (object-widening-set! ,newo #f)
	      ,newo)
	  `(let ((,newo ,(e o e)))
	      (if (object? ,newo)
		  (if (object-widening ,newo)
		      (begin
			 ((@ object-class-num-set! __object)
			  ,newo
			  ((@ class-num __object)
			   ((@ class-super __object)
			    ((@ object-class __object) ,newo))))
			 (object-widening-set! ,newo #f)
			 ,newo)
		      (error "shrink!" "Not a wide object" ,newo))
		  (error "shrink!" "Not a wide object" ,newo))))))

;*---------------------------------------------------------------------*/
;*    object-epairify ...                                              */
;*---------------------------------------------------------------------*/
(define (object-epairify obj epair)
   (if (epair? epair)
       (if (pair? obj)
	   (econs (car obj) (cdr obj) (cer epair))
	   (object-epairify `(begin ,obj) epair))
       obj))

;*---------------------------------------------------------------------*/
;*    find-slot-offset ...                                             */
;*---------------------------------------------------------------------*/
(define (find-slot-offset slots::pair-nil name::symbol form sexp)
   (let loop ((slots slots)
	      (i 0))
      (cond
	 ((null? slots)
	  (error form (format "Field unknown \"~a\"" name) sexp))
	 ((eq? (slot-id (car slots)) name)
	  i)
	 (else   
	  (loop (cdr slots) (+fx i 1))))))

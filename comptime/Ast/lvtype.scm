;*=====================================================================*/
;*    serrano/prgm/project/bigloo/comptime/Ast/lvtype.scm              */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed Jul  3 11:58:06 1996                          */
;*    Last change :  Fri Feb  3 14:28:25 2012 (serrano)                */
;*    -------------------------------------------------------------    */
;*    This types a node (straightforward typing used by passes, i.e.,  */
;*    Coerce and Cnst, which occur after the Cfa). This pass only      */
;*    propagates types information found in subnodes.                  */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module ast_lvtype
   (import  type_type
	    type_cache
	    type_typeof
	    tools_shape
	    tools_error
	    ast_var
	    ast_node)
   (export  (lvtype-ast! ::pair-nil)
	    (lvtype-node::node ::node)
	    (generic lvtype-node! ::node)))

;*---------------------------------------------------------------------*/
;*    lvtype-ast! ...                                                  */
;*---------------------------------------------------------------------*/
(define (lvtype-ast! ast)
   (for-each (lambda (g)
		(lvtype-node! (sfun-body (global-value g))))
	     ast)
   ast)

;*---------------------------------------------------------------------*/
;*    lvtype-node ...                                                  */
;*---------------------------------------------------------------------*/
(define (lvtype-node::node node::node)
   (lvtype-node! node)
   node)

;*---------------------------------------------------------------------*/
;*    lvtype-node! ...                                                 */
;*---------------------------------------------------------------------*/
(define-generic (lvtype-node! node::node))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::atom ...                                          */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::atom)
   node)

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::kwote ...                                         */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::kwote)
   node)

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::var ...                                           */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::var)
   (with-access::var node (type variable)
      (when (eq? type *_*)
	 (set! type (variable-type variable))))
   node)

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::closure ...                                       */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::closure)
   (internal-error "lvtype-node!" "Unexpected closure" (shape node)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::sequence ...                                      */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::sequence)
   (with-access::sequence node (type nodes)
      (lvtype-node*! nodes)
      (when (eq? type *_*)
	 (set! type (get-type node)))))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::app ...                                           */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::app)
   (with-access::app node (type fun args)
      (lvtype-node*! args)
      (when (eq? type *_*)
	 (set! type (get-type node)))))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::app-ly ...                                        */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::app-ly)
   (with-access::app-ly node (fun arg)
      (lvtype-node! fun)
      (lvtype-node! arg)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::funcall ...                                       */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::funcall)
   (with-access::funcall node (fun args)
      (lvtype-node! fun)
      (lvtype-node*! args)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::extern ...                                        */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::extern)
   (with-access::extern node (expr* type)
      (lvtype-node*! expr*)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::cast ...                                          */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::cast)
   (with-access::cast node (arg type)
      (lvtype-node! arg)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::setq ...                                          */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::setq)
   (with-access::setq node (var value)
      (lvtype-node! value)
      (lvtype-node! var)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::conditional ...                                   */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::conditional)
   (with-access::conditional node (type test true false)
       (lvtype-node! test)
       (lvtype-node! true)
       (lvtype-node! false)
       (when (eq? type *_*)
	  (set! type (get-type node)))))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::fail ...                                          */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::fail)
   (with-access::fail node (type proc msg obj)
      (lvtype-node! proc)
      (lvtype-node! msg)
      (lvtype-node! obj)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::select ...                                        */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::select)
   (with-access::select node (clauses test)
      (lvtype-node! test)
      (for-each (lambda (clause)
		   (lvtype-node! (cdr clause)))
		clauses)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::let-fun ...                                       */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::let-fun)
   (with-access::let-fun node (type body locals)
      (for-each (lambda (local)
		   (lvtype-node! (sfun-body (local-value local))))
		locals)
      (lvtype-node! body)
      (when (eq? type *_*)
	 (set! type (get-type body)))))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::let-var ...                                       */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::let-var)
   (with-access::let-var node (type body bindings)
      (for-each (lambda (binding)
		   (let ((var (car binding))
			 (val (cdr binding)))
		      (lvtype-node! val)
		      (set-variable-type! var (get-type val))))
		bindings)
      (lvtype-node! body)
      (when (eq? type *_*)
	 (set! type (get-type body)))))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::set-ex-it ...                                     */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::set-ex-it)
   (with-access::set-ex-it node (var body)
      (lvtype-node! body)
      (lvtype-node! var)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::jump-ex-it ...                                    */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::jump-ex-it)
   (with-access::jump-ex-it node (exit value)
      (lvtype-node! exit) 
      (lvtype-node! value)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::make-box ...                                      */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::make-box)
   (with-access::make-box node (value)
      (lvtype-node! value)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::box-set! ...                                      */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::box-set!)
   (with-access::box-set! node (var value)
      (lvtype-node! var)
      (lvtype-node! value)))

;*---------------------------------------------------------------------*/
;*    lvtype-node! ::box-ref ...                                       */
;*---------------------------------------------------------------------*/
(define-method (lvtype-node! node::box-ref)
   (with-access::box-ref node (var)
      (lvtype-node! var)))

;*---------------------------------------------------------------------*/
;*    lvtype-node*! ...                                                */
;*---------------------------------------------------------------------*/
(define (lvtype-node*! node*)
   (for-each lvtype-node! node*))
   
;*---------------------------------------------------------------------*/
;*    set-variable-type! ...                                           */
;*---------------------------------------------------------------------*/
(define (set-variable-type! variable::variable type::type)
   (let ((ntype (if (eq? type *_*) *obj* type))
	 (otype (variable-type variable))) 
      (if (eq? otype *_*)
	  (variable-type-set! variable ntype))))


;; ==========================================================
;; Class accessors
;; Bigloo (3.9b)
;; Inria -- Sophia Antipolis     Fri Nov 23 09:35:17 CET 2012 
;; (bigloo -classgen Inline/size.scm)
;; ==========================================================

;; The directives
(directives

;; sized-sequence
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-sized-sequence::sized-sequence loc1201::obj type1202::type side-effect1204::obj key1205::obj nodes1206::obj unsafe1207::bool size1208::long)
    (inline sized-sequence?::bool ::obj)
    (sized-sequence-nil::sized-sequence)
    (inline sized-sequence-size::long ::sized-sequence)
    (inline sized-sequence-unsafe::bool ::sized-sequence)
    (inline sized-sequence-nodes::obj ::sized-sequence)
    (inline sized-sequence-key::obj ::sized-sequence)
    (inline sized-sequence-key-set! ::sized-sequence ::obj)
    (inline sized-sequence-side-effect::obj ::sized-sequence)
    (inline sized-sequence-side-effect-set! ::sized-sequence ::obj)
    (inline sized-sequence-type::type ::sized-sequence)
    (inline sized-sequence-type-set! ::sized-sequence ::type)
    (inline sized-sequence-loc::obj ::sized-sequence))))

;; sized-sync
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-sized-sync::sized-sync loc1194::obj type1195::type mutex1196::node prelock1197::node nodes1198::pair-nil size1199::long)
    (inline sized-sync?::bool ::obj)
    (sized-sync-nil::sized-sync)
    (inline sized-sync-size::long ::sized-sync)
    (inline sized-sync-nodes::pair-nil ::sized-sync)
    (inline sized-sync-prelock::node ::sized-sync)
    (inline sized-sync-prelock-set! ::sized-sync ::node)
    (inline sized-sync-mutex::node ::sized-sync)
    (inline sized-sync-mutex-set! ::sized-sync ::node)
    (inline sized-sync-type::type ::sized-sync)
    (inline sized-sync-type-set! ::sized-sync ::type)
    (inline sized-sync-loc::obj ::sized-sync))))

;; sized-select
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-sized-select::sized-select loc1185::obj type1186::type side-effect1187::obj key1188::obj test1189::node clauses1190::obj item-type1191::type size1192::long)
    (inline sized-select?::bool ::obj)
    (sized-select-nil::sized-select)
    (inline sized-select-size::long ::sized-select)
    (inline sized-select-item-type::type ::sized-select)
    (inline sized-select-clauses::obj ::sized-select)
    (inline sized-select-test::node ::sized-select)
    (inline sized-select-test-set! ::sized-select ::node)
    (inline sized-select-key::obj ::sized-select)
    (inline sized-select-key-set! ::sized-select ::obj)
    (inline sized-select-side-effect::obj ::sized-select)
    (inline sized-select-side-effect-set! ::sized-select ::obj)
    (inline sized-select-type::type ::sized-select)
    (inline sized-select-type-set! ::sized-select ::type)
    (inline sized-select-loc::obj ::sized-select))))

;; sized-let-fun
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-sized-let-fun::sized-let-fun loc1175::obj type1176::type side-effect1177::obj key1178::obj locals1179::obj body1180::node size1181::long)
    (inline sized-let-fun?::bool ::obj)
    (sized-let-fun-nil::sized-let-fun)
    (inline sized-let-fun-size::long ::sized-let-fun)
    (inline sized-let-fun-body::node ::sized-let-fun)
    (inline sized-let-fun-body-set! ::sized-let-fun ::node)
    (inline sized-let-fun-locals::obj ::sized-let-fun)
    (inline sized-let-fun-locals-set! ::sized-let-fun ::obj)
    (inline sized-let-fun-key::obj ::sized-let-fun)
    (inline sized-let-fun-key-set! ::sized-let-fun ::obj)
    (inline sized-let-fun-side-effect::obj ::sized-let-fun)
    (inline sized-let-fun-side-effect-set! ::sized-let-fun ::obj)
    (inline sized-let-fun-type::type ::sized-let-fun)
    (inline sized-let-fun-type-set! ::sized-let-fun ::type)
    (inline sized-let-fun-loc::obj ::sized-let-fun))))

;; sized-let-var
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (static
    (inline make-sized-let-var::sized-let-var loc1165::obj type1166::type side-effect1167::obj key1168::obj bindings1169::obj body1170::node removable?1171::bool size1172::long)
    (inline sized-let-var?::bool ::obj)
    (sized-let-var-nil::sized-let-var)
    (inline sized-let-var-size::long ::sized-let-var)
    (inline sized-let-var-removable?::bool ::sized-let-var)
    (inline sized-let-var-removable?-set! ::sized-let-var ::bool)
    (inline sized-let-var-body::node ::sized-let-var)
    (inline sized-let-var-body-set! ::sized-let-var ::node)
    (inline sized-let-var-bindings::obj ::sized-let-var)
    (inline sized-let-var-bindings-set! ::sized-let-var ::obj)
    (inline sized-let-var-key::obj ::sized-let-var)
    (inline sized-let-var-key-set! ::sized-let-var ::obj)
    (inline sized-let-var-side-effect::obj ::sized-let-var)
    (inline sized-let-var-side-effect-set! ::sized-let-var ::obj)
    (inline sized-let-var-type::type ::sized-let-var)
    (inline sized-let-var-type-set! ::sized-let-var ::type)
    (inline sized-let-var-loc::obj ::sized-let-var)))))

;; The definitions
(cond-expand (bigloo-class-sans
;; sized-sequence
(define-inline (make-sized-sequence::sized-sequence loc1201::obj type1202::type side-effect1204::obj key1205::obj nodes1206::obj unsafe1207::bool size1208::long) (instantiate::sized-sequence (loc loc1201) (type type1202) (side-effect side-effect1204) (key key1205) (nodes nodes1206) (unsafe unsafe1207) (size size1208)))
(define-inline (sized-sequence?::bool obj::obj) ((@ isa? __object) obj (@ sized-sequence inline_size)))
(define (sized-sequence-nil::sized-sequence) (class-nil (@ sized-sequence inline_size)))
(define-inline (sized-sequence-size::long o::sized-sequence) (with-access::sized-sequence o (size) size))
(define-inline (sized-sequence-size-set! o::sized-sequence v::long) (with-access::sized-sequence o (size) (set! size v)))
(define-inline (sized-sequence-unsafe::bool o::sized-sequence) (with-access::sized-sequence o (unsafe) unsafe))
(define-inline (sized-sequence-unsafe-set! o::sized-sequence v::bool) (with-access::sized-sequence o (unsafe) (set! unsafe v)))
(define-inline (sized-sequence-nodes::obj o::sized-sequence) (with-access::sized-sequence o (nodes) nodes))
(define-inline (sized-sequence-nodes-set! o::sized-sequence v::obj) (with-access::sized-sequence o (nodes) (set! nodes v)))
(define-inline (sized-sequence-key::obj o::sized-sequence) (with-access::sized-sequence o (key) key))
(define-inline (sized-sequence-key-set! o::sized-sequence v::obj) (with-access::sized-sequence o (key) (set! key v)))
(define-inline (sized-sequence-side-effect::obj o::sized-sequence) (with-access::sized-sequence o (side-effect) side-effect))
(define-inline (sized-sequence-side-effect-set! o::sized-sequence v::obj) (with-access::sized-sequence o (side-effect) (set! side-effect v)))
(define-inline (sized-sequence-type::type o::sized-sequence) (with-access::sized-sequence o (type) type))
(define-inline (sized-sequence-type-set! o::sized-sequence v::type) (with-access::sized-sequence o (type) (set! type v)))
(define-inline (sized-sequence-loc::obj o::sized-sequence) (with-access::sized-sequence o (loc) loc))
(define-inline (sized-sequence-loc-set! o::sized-sequence v::obj) (with-access::sized-sequence o (loc) (set! loc v)))

;; sized-sync
(define-inline (make-sized-sync::sized-sync loc1194::obj type1195::type mutex1196::node prelock1197::node nodes1198::pair-nil size1199::long) (instantiate::sized-sync (loc loc1194) (type type1195) (mutex mutex1196) (prelock prelock1197) (nodes nodes1198) (size size1199)))
(define-inline (sized-sync?::bool obj::obj) ((@ isa? __object) obj (@ sized-sync inline_size)))
(define (sized-sync-nil::sized-sync) (class-nil (@ sized-sync inline_size)))
(define-inline (sized-sync-size::long o::sized-sync) (with-access::sized-sync o (size) size))
(define-inline (sized-sync-size-set! o::sized-sync v::long) (with-access::sized-sync o (size) (set! size v)))
(define-inline (sized-sync-nodes::pair-nil o::sized-sync) (with-access::sized-sync o (nodes) nodes))
(define-inline (sized-sync-nodes-set! o::sized-sync v::pair-nil) (with-access::sized-sync o (nodes) (set! nodes v)))
(define-inline (sized-sync-prelock::node o::sized-sync) (with-access::sized-sync o (prelock) prelock))
(define-inline (sized-sync-prelock-set! o::sized-sync v::node) (with-access::sized-sync o (prelock) (set! prelock v)))
(define-inline (sized-sync-mutex::node o::sized-sync) (with-access::sized-sync o (mutex) mutex))
(define-inline (sized-sync-mutex-set! o::sized-sync v::node) (with-access::sized-sync o (mutex) (set! mutex v)))
(define-inline (sized-sync-type::type o::sized-sync) (with-access::sized-sync o (type) type))
(define-inline (sized-sync-type-set! o::sized-sync v::type) (with-access::sized-sync o (type) (set! type v)))
(define-inline (sized-sync-loc::obj o::sized-sync) (with-access::sized-sync o (loc) loc))
(define-inline (sized-sync-loc-set! o::sized-sync v::obj) (with-access::sized-sync o (loc) (set! loc v)))

;; sized-select
(define-inline (make-sized-select::sized-select loc1185::obj type1186::type side-effect1187::obj key1188::obj test1189::node clauses1190::obj item-type1191::type size1192::long) (instantiate::sized-select (loc loc1185) (type type1186) (side-effect side-effect1187) (key key1188) (test test1189) (clauses clauses1190) (item-type item-type1191) (size size1192)))
(define-inline (sized-select?::bool obj::obj) ((@ isa? __object) obj (@ sized-select inline_size)))
(define (sized-select-nil::sized-select) (class-nil (@ sized-select inline_size)))
(define-inline (sized-select-size::long o::sized-select) (with-access::sized-select o (size) size))
(define-inline (sized-select-size-set! o::sized-select v::long) (with-access::sized-select o (size) (set! size v)))
(define-inline (sized-select-item-type::type o::sized-select) (with-access::sized-select o (item-type) item-type))
(define-inline (sized-select-item-type-set! o::sized-select v::type) (with-access::sized-select o (item-type) (set! item-type v)))
(define-inline (sized-select-clauses::obj o::sized-select) (with-access::sized-select o (clauses) clauses))
(define-inline (sized-select-clauses-set! o::sized-select v::obj) (with-access::sized-select o (clauses) (set! clauses v)))
(define-inline (sized-select-test::node o::sized-select) (with-access::sized-select o (test) test))
(define-inline (sized-select-test-set! o::sized-select v::node) (with-access::sized-select o (test) (set! test v)))
(define-inline (sized-select-key::obj o::sized-select) (with-access::sized-select o (key) key))
(define-inline (sized-select-key-set! o::sized-select v::obj) (with-access::sized-select o (key) (set! key v)))
(define-inline (sized-select-side-effect::obj o::sized-select) (with-access::sized-select o (side-effect) side-effect))
(define-inline (sized-select-side-effect-set! o::sized-select v::obj) (with-access::sized-select o (side-effect) (set! side-effect v)))
(define-inline (sized-select-type::type o::sized-select) (with-access::sized-select o (type) type))
(define-inline (sized-select-type-set! o::sized-select v::type) (with-access::sized-select o (type) (set! type v)))
(define-inline (sized-select-loc::obj o::sized-select) (with-access::sized-select o (loc) loc))
(define-inline (sized-select-loc-set! o::sized-select v::obj) (with-access::sized-select o (loc) (set! loc v)))

;; sized-let-fun
(define-inline (make-sized-let-fun::sized-let-fun loc1175::obj type1176::type side-effect1177::obj key1178::obj locals1179::obj body1180::node size1181::long) (instantiate::sized-let-fun (loc loc1175) (type type1176) (side-effect side-effect1177) (key key1178) (locals locals1179) (body body1180) (size size1181)))
(define-inline (sized-let-fun?::bool obj::obj) ((@ isa? __object) obj (@ sized-let-fun inline_size)))
(define (sized-let-fun-nil::sized-let-fun) (class-nil (@ sized-let-fun inline_size)))
(define-inline (sized-let-fun-size::long o::sized-let-fun) (with-access::sized-let-fun o (size) size))
(define-inline (sized-let-fun-size-set! o::sized-let-fun v::long) (with-access::sized-let-fun o (size) (set! size v)))
(define-inline (sized-let-fun-body::node o::sized-let-fun) (with-access::sized-let-fun o (body) body))
(define-inline (sized-let-fun-body-set! o::sized-let-fun v::node) (with-access::sized-let-fun o (body) (set! body v)))
(define-inline (sized-let-fun-locals::obj o::sized-let-fun) (with-access::sized-let-fun o (locals) locals))
(define-inline (sized-let-fun-locals-set! o::sized-let-fun v::obj) (with-access::sized-let-fun o (locals) (set! locals v)))
(define-inline (sized-let-fun-key::obj o::sized-let-fun) (with-access::sized-let-fun o (key) key))
(define-inline (sized-let-fun-key-set! o::sized-let-fun v::obj) (with-access::sized-let-fun o (key) (set! key v)))
(define-inline (sized-let-fun-side-effect::obj o::sized-let-fun) (with-access::sized-let-fun o (side-effect) side-effect))
(define-inline (sized-let-fun-side-effect-set! o::sized-let-fun v::obj) (with-access::sized-let-fun o (side-effect) (set! side-effect v)))
(define-inline (sized-let-fun-type::type o::sized-let-fun) (with-access::sized-let-fun o (type) type))
(define-inline (sized-let-fun-type-set! o::sized-let-fun v::type) (with-access::sized-let-fun o (type) (set! type v)))
(define-inline (sized-let-fun-loc::obj o::sized-let-fun) (with-access::sized-let-fun o (loc) loc))
(define-inline (sized-let-fun-loc-set! o::sized-let-fun v::obj) (with-access::sized-let-fun o (loc) (set! loc v)))

;; sized-let-var
(define-inline (make-sized-let-var::sized-let-var loc1165::obj type1166::type side-effect1167::obj key1168::obj bindings1169::obj body1170::node removable?1171::bool size1172::long) (instantiate::sized-let-var (loc loc1165) (type type1166) (side-effect side-effect1167) (key key1168) (bindings bindings1169) (body body1170) (removable? removable?1171) (size size1172)))
(define-inline (sized-let-var?::bool obj::obj) ((@ isa? __object) obj (@ sized-let-var inline_size)))
(define (sized-let-var-nil::sized-let-var) (class-nil (@ sized-let-var inline_size)))
(define-inline (sized-let-var-size::long o::sized-let-var) (with-access::sized-let-var o (size) size))
(define-inline (sized-let-var-size-set! o::sized-let-var v::long) (with-access::sized-let-var o (size) (set! size v)))
(define-inline (sized-let-var-removable?::bool o::sized-let-var) (with-access::sized-let-var o (removable?) removable?))
(define-inline (sized-let-var-removable?-set! o::sized-let-var v::bool) (with-access::sized-let-var o (removable?) (set! removable? v)))
(define-inline (sized-let-var-body::node o::sized-let-var) (with-access::sized-let-var o (body) body))
(define-inline (sized-let-var-body-set! o::sized-let-var v::node) (with-access::sized-let-var o (body) (set! body v)))
(define-inline (sized-let-var-bindings::obj o::sized-let-var) (with-access::sized-let-var o (bindings) bindings))
(define-inline (sized-let-var-bindings-set! o::sized-let-var v::obj) (with-access::sized-let-var o (bindings) (set! bindings v)))
(define-inline (sized-let-var-key::obj o::sized-let-var) (with-access::sized-let-var o (key) key))
(define-inline (sized-let-var-key-set! o::sized-let-var v::obj) (with-access::sized-let-var o (key) (set! key v)))
(define-inline (sized-let-var-side-effect::obj o::sized-let-var) (with-access::sized-let-var o (side-effect) side-effect))
(define-inline (sized-let-var-side-effect-set! o::sized-let-var v::obj) (with-access::sized-let-var o (side-effect) (set! side-effect v)))
(define-inline (sized-let-var-type::type o::sized-let-var) (with-access::sized-let-var o (type) type))
(define-inline (sized-let-var-type-set! o::sized-let-var v::type) (with-access::sized-let-var o (type) (set! type v)))
(define-inline (sized-let-var-loc::obj o::sized-let-var) (with-access::sized-let-var o (loc) loc))
(define-inline (sized-let-var-loc-set! o::sized-let-var v::obj) (with-access::sized-let-var o (loc) (set! loc v)))
))

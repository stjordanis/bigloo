/*=====================================================================*/
/*    serrano/prgm/project/bigloo/runtime/Include/bigloo_struct.h      */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Sat Mar  5 08:05:01 2016                          */
/*    Last change :  Tue Mar 15 21:56:52 2016 (serrano)                */
/*    Copyright   :  2016 Manuel Serrano                               */
/*    -------------------------------------------------------------    */
/*    Bigloo STRUCTs                                                   */
/*=====================================================================*/
#ifndef BIGLOO_STRUCT_H 
#define BIGLOO_STRUCT_H

/*---------------------------------------------------------------------*/
/*    Does someone really wants C++ here?                              */
/*---------------------------------------------------------------------*/
#ifdef __cplusplus
extern "C" {
#endif
#ifdef __cplusplus_just_for_emacs_indent
}
#endif

/*---------------------------------------------------------------------*/
/*    extern                                                           */
/*---------------------------------------------------------------------*/
BGL_RUNTIME_DECL obj_t create_struct( obj_t key, int len );

/*---------------------------------------------------------------------*/
/*    bgl_struct ...                                                   */
/*---------------------------------------------------------------------*/
struct bgl_struct {
#if( !defined( TAG_STRUCTURE ) )
   header_t header;
#endif
   /* the key (i.e., the name) of the structure */
   obj_t key;
   /* the length (i.e., the slot number) */
   long length;
   /* the packed slots */
   obj_t obj0;
};

#define STRUCT( o ) CSTRUCTURE( o )->struct_t

#define STRUCT_SIZE (sizeof( struct bgl_struct ))

/*---------------------------------------------------------------------*/
/*    tagging                                                          */
/*---------------------------------------------------------------------*/
#if( defined( TAG_STRUCTURE ) )
#   define BSTRUCTURE( r ) ((obj_t)((long)p + TAG_STRUCTURE))
#   define CSTRUCTURE( p ) ((obj_t)((long)p - TAG_STRUCTURE))
#   define STRUCTP( c ) ((c && ((((long)c)&TAG_MASK) == TAG_STRUCTURE)))
#else
#   define BSTRUCTURE( p ) BREF( p )
#   define CSTRUCTURE( p ) CREF( p )
#   define STRUCTP( c ) (POINTERP( c ) && (TYPE( c ) == STRUCT_TYPE))
#endif

/*---------------------------------------------------------------------*/
/*    api                                                              */
/*---------------------------------------------------------------------*/
#define STRUCT_LENGTH( c ) STRUCT( c ).length
   
#define STRUCT_KEY( c ) STRUCT( c ).key
#define STRUCT_KEY_SET( c, k ) (BASSIGN( STRUCT_KEY( c ), k, c))

#define STRUCT_REF( c, i ) ((&(STRUCT(c).obj0))[ i ])
#define STRUCT_SET( c, i, o ) (BASSIGN( STRUCT_REF( c, i ), o, c))

/*---------------------------------------------------------------------*/
/*    C++                                                              */
/*---------------------------------------------------------------------*/
#ifdef __cplusplus
}
#endif
#endif


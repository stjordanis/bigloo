/*=====================================================================*/
/*    serrano/prgm/project/bigloo/api/alsa/src/Clib/bglalsa.c          */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Thu Jun 23 18:07:00 2011                          */
/*    Last change :  Tue Jul 12 10:26:54 2011 (serrano)                */
/*    Copyright   :  2011 Manuel Serrano                               */
/*    -------------------------------------------------------------    */
/*    Bigloo ALSA specific functions                                   */
/*=====================================================================*/
#include <alsa/asoundlib.h>
#include <bigloo.h>
#include "bglalsa.h"
#include "bglpcm.h"
#include "bglctl.h"
#include "bglmixer.h"

/*---------------------------------------------------------------------*/
/*    OBJ_TO_SND_PCM                                                   */
/*---------------------------------------------------------------------*/
#define OBJ_TO_SND_PCM( o ) \
   (((BgL_alsazd2sndzd2pcmz00_bglt)o)->BgL_z42builtinz42)

/*---------------------------------------------------------------------*/
/*    OBJ_TO_SND_CTL                                                   */
/*---------------------------------------------------------------------*/
#define OBJ_TO_SND_CTL( o ) \
   (((BgL_alsazd2sndzd2ctlz00_bglt)o)->BgL_z42builtinz42)

/*---------------------------------------------------------------------*/
/*    OBJ_TO_SND_MIXER                                                 */
/*---------------------------------------------------------------------*/
#define OBJ_TO_SND_MIXER( o ) \
   (((BgL_alsazd2sndzd2mixerz00_bglt)o)->BgL_z42builtinz42)

/*---------------------------------------------------------------------*/
/*    alsa-snd-card-info bigloo object                                 */
/*---------------------------------------------------------------------*/
#define BGL_SND_CTL_CARD_INFO_CTL( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_ctlz00
#define BGL_SND_CTL_CARD_INFO_CARD( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_cardz00
#define BGL_SND_CTL_CARD_INFO_ID( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_idz00
#define BGL_SND_CTL_CARD_INFO_DRIVER( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_driverz00
#define BGL_SND_CTL_CARD_INFO_NAME( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_namez00
#define BGL_SND_CTL_CARD_INFO_LONGNAME( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_longnamez00
#define BGL_SND_CTL_CARD_INFO_MIXERNAME( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_mixernamez00
#define BGL_SND_CTL_CARD_INFO_COMPONENTS( o ) \
   ((BgL_alsazd2sndzd2ctlzd2cardzd2infoz00_bglt)o)->BgL_componentsz00

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_pcm_open ...                                             */
/*---------------------------------------------------------------------*/
int
bgl_snd_pcm_open( obj_t o, char *name, snd_pcm_stream_t stream, int mode ) {
   return snd_pcm_open( &(OBJ_TO_SND_PCM( o )), name, stream, mode );
}

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_ctl_open ...                                             */
/*---------------------------------------------------------------------*/
int
bgl_snd_ctl_open( obj_t o, char *card, int mode ) {
   return snd_ctl_open( &(OBJ_TO_SND_CTL( o )), card, mode );
}

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_mixer_open ...                                           */
/*---------------------------------------------------------------------*/
int
bgl_snd_mixer_open( obj_t o ) {
   return snd_mixer_open( &(OBJ_TO_SND_MIXER( o )), 0 );
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bgl_snd_ctl_card_info_init ...                                   */
/*---------------------------------------------------------------------*/
void
bgl_snd_ctl_card_info_init( obj_t o ) {
   int err;
   snd_ctl_card_info_t *info;
   snd_ctl_card_info_alloca( &info );
   snd_ctl_t *handle = OBJ_TO_SND_CTL( BGL_SND_CTL_CARD_INFO_CTL( o ) );
   
   if( (err = snd_ctl_card_info( handle, info )) < 0 ) {
      bgl_alsa_error( "alsa-snd-ctl-card-info",
		      (char *)snd_strerror( err ),
		      o );
   }
   
   BGL_SND_CTL_CARD_INFO_CARD( o ) =
      snd_ctl_card_info_get_card( info );
   BGL_SND_CTL_CARD_INFO_ID( o ) =
      string_to_bstring( snd_ctl_card_info_get_id( info ) );
   BGL_SND_CTL_CARD_INFO_DRIVER( o ) =
      string_to_bstring( snd_ctl_card_info_get_driver( info ) );
   BGL_SND_CTL_CARD_INFO_NAME( o ) =
      string_to_bstring( snd_ctl_card_info_get_name( info ) );
   BGL_SND_CTL_CARD_INFO_LONGNAME( o ) =
      string_to_bstring( snd_ctl_card_info_get_longname( info ) );
   BGL_SND_CTL_CARD_INFO_MIXERNAME( o ) =
      string_to_bstring( snd_ctl_card_info_get_mixername( info ) );
   BGL_SND_CTL_CARD_INFO_COMPONENTS( o ) =
      string_to_bstring( snd_ctl_card_info_get_components( info ) );
}

/*---------------------------------------------------------------------*/
/*    snd_pcm_hw_params_t *                                            */
/*    bgl_snd_pcm_hw_params_malloc ...                                 */
/*---------------------------------------------------------------------*/
snd_pcm_hw_params_t *
bgl_snd_pcm_hw_params_malloc() {
   snd_pcm_hw_params_t *hw = NULL;

   snd_pcm_hw_params_malloc( &hw );

   return hw;
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bgl_snd_pcm_hw_params_free ...                                   */
/*---------------------------------------------------------------------*/
void
bgl_snd_pcm_hw_params_free( snd_pcm_hw_params_t *hw ) {
   snd_pcm_hw_params_free( hw );
}

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_pcm_hw_params_set_rate_near ...                          */
/*---------------------------------------------------------------------*/
int
bgl_snd_pcm_hw_params_set_rate_near( snd_pcm_t *pcm,
				     snd_pcm_hw_params_t *hw,
				     unsigned int rate ) {
   int err = snd_pcm_hw_params_set_rate_near( pcm, hw, &rate, 0L );

   return err < 0 ? err : rate;
}

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_pcm_hw_params_set_buffer_size_near ...                   */
/*---------------------------------------------------------------------*/
int
bgl_snd_pcm_hw_params_set_buffer_size_near( snd_pcm_t *pcm,
					    snd_pcm_hw_params_t *hw,
					    snd_pcm_uframes_t uframes ) {
   return snd_pcm_hw_params_set_buffer_size_near( pcm, hw, &uframes );
}

/*---------------------------------------------------------------------*/
/*    int                                                              */
/*    bgl_snd_pcm_hw_params_set_period_size_near ...                   */
/*---------------------------------------------------------------------*/
int
bgl_snd_pcm_hw_params_set_period_size_near( snd_pcm_t *pcm,
					    snd_pcm_hw_params_t *hw,
					    snd_pcm_uframes_t val ) {
   return snd_pcm_hw_params_set_period_size_near( pcm, hw, &val, 0L );
}

/*---------------------------------------------------------------------*/
/*    snd_pcm_sw_params_t *                                            */
/*    bgl_snd_pcm_sw_params_malloc ...                                 */
/*---------------------------------------------------------------------*/
snd_pcm_sw_params_t *
bgl_snd_pcm_sw_params_malloc() {
   snd_pcm_sw_params_t *sw = NULL;

   snd_pcm_sw_params_malloc( &sw );

   return sw;
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bgl_snd_pcm_sw_params_free ...                                   */
/*---------------------------------------------------------------------*/
void
bgl_snd_pcm_sw_params_free( snd_pcm_sw_params_t *sw ) {
   snd_pcm_sw_params_free( sw );
}

/*---------------------------------------------------------------------*/
/*    long                                                             */
/*    bgl_snd_pcm_write ...                                            */
/*---------------------------------------------------------------------*/
long
bgl_snd_pcm_write( obj_t o, char *buf, long sz ) {
   snd_pcm_uframes_t frames;
   snd_pcm_sframes_t written;
   snd_pcm_t *pcm = OBJ_TO_SND_PCM( o );

   frames = snd_pcm_bytes_to_frames( pcm, sz );
   if( frames < 0 ) {
      return bgl_alsa_error(
	 "alsa-snd-pcm-write",
	 (char *)snd_strerror( written ),
	 o );
   }

   written = snd_pcm_writei( pcm, buf, frames );

/*    if( written == -EINTR ) {                                        */
/*       fprintf( stderr, "%s:%d, snd_pcm_writei sz=%d frames=%d -> EINTR\n", */
/* 	       __FILE__, __LINE__, sz, frames, written );              */
/*    } else if( written == -EPIPE ) {                                 */
/*       fprintf( stderr, "%s:%d snd_pcm_writei sz=%d frames=%d -> EPIPE\n", */
/* 	       __FILE__, __LINE__, sz, frames, written );              */
/*    } else {                                                         */
/*       fprintf( stderr, "%s:%dsnd_pcm_writei sz=%d frames=%d -> %d\n", */
/* 	       __FILE__, __LINE__, sz, frames, written );              */
/*    }                                                                */
   
   if( written == -EINTR )
       written = 0;
   else if( written == -EPIPE ) {
      if( snd_pcm_prepare( pcm ) >= 0 )
	 written = snd_pcm_writei( pcm, buf, frames );
   }

   if( written >= 0 ) {
      return snd_pcm_frames_to_bytes( pcm, written );
   } else {
      if( snd_pcm_state( pcm ) == SND_PCM_STATE_SUSPENDED ) {
	 snd_pcm_resume( pcm );
	 
	 if( snd_pcm_state( pcm ) == SND_PCM_STATE_SUSPENDED ) {
	    return bgl_alsa_error(
	       "alsa-snd-pcm-write",
	       "device suspended",
	       o );
	 }
      } else{
	 return bgl_alsa_error(
	    "alsa-snd-pcm-write",
	    (char *)snd_strerror( written ),
	    o );
      }
      return 0;
   }
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bgl_snd_pcm_flush ...                                            */
/*---------------------------------------------------------------------*/
void
bgl_snd_pcm_flush( obj_t o ) {
   snd_pcm_t *pcm = OBJ_TO_SND_PCM( o );
   
   snd_pcm_drop( pcm );
   snd_pcm_prepare( pcm );
}

/*---------------------------------------------------------------------*/
/*    char *                                                           */
/*    bgl_snd_card_get_name ...                                        */
/*---------------------------------------------------------------------*/
char *
bgl_snd_card_get_name( int i ) {
   char *name;
   int err = snd_card_get_name( i, &name );

   if( !err ) {
      return name;
   } else {
      bgl_alsa_error( "alsa-get-cards",
		      (char *)snd_strerror( err ),
		      BINT( i ) );
      return 0L;
   }
}      
   
/*---------------------------------------------------------------------*/
/*    char *                                                           */
/*    bgl_snd_card_get_longname ...                                    */
/*---------------------------------------------------------------------*/
char *
bgl_snd_card_get_longname( int i ) {
   char *longname;
   int err = snd_card_get_longname( i, &longname );

   if( !err ) {
      return longname;
   } else {
      bgl_alsa_error( "alsa-get-cards",
		      (char *)snd_strerror( err ),
		      BINT( i ) );
      return 0L;
   }
}      

   
/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bgl_snd_devices_list ...                                         */
/*---------------------------------------------------------------------*/
obj_t
bgl_snd_devices_list( char *iface ) {
   void **hints;
   int err = snd_device_name_hint( -1, (const char*)iface, &hints );
   obj_t acc = BNIL;

   if( err >= 0 ) {
      void **h = hints;
      while( *h ) {
	 char *s = snd_device_name_get_hint( *h++, "NAME" );
	 acc = MAKE_PAIR( string_to_bstring( s ), acc );
	 free( s );
      }

      snd_device_name_free_hint( hints );
      
      return acc;
   } else {
      return BNIL;
   }
}      
   
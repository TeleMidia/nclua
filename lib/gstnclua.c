/* gstnclua.c -- NCLua GStreamer plugin.
   Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

This file is part of NCLua.

NCLua is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

NCLua is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  */

#include <config.h>

#include <glib.h>
#include <glib/gstdio.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* *INDENT-OFF* */
#include "macros.h"             /* for pragma diagnostic stuff */
PRAGMA_DIAGNOSTIC_IGNORE (-Wbad-function-cast)

PRAGMA_DIAGNOSTIC_PUSH ()
PRAGMA_DIAGNOSTIC_IGNORE (-Wcast-qual)
PRAGMA_DIAGNOSTIC_IGNORE (-Wpedantic)
PRAGMA_DIAGNOSTIC_IGNORE (-Wvariadic-macros)
PRAGMA_DIAGNOSTIC_IGNORE (-Wconversion)
#include <gst/gst.h>
#include <gst/base/gstpushsrc.h>
#include <gst/video/gstvideometa.h>
PRAGMA_DIAGNOSTIC_POP ()
/* *INDENT-ON* */

#include "nclua.h"
#include "ncluaw.h"
#include "luax-macros.h"

/* GstNCLua class data.  */
typedef struct _GstNCLuaClass
{
  GstPushSrcClass parent_class;
} GstNCLuaClass;

/* GStNCLua instance data.  */
typedef struct _GstNCLua
{
  GstPushSrc element;
  GstVideoInfo info;            /* current video info */
  volatile gint G_GNUC_MAY_ALIAS new_info;      /* flags info updates  */
  ncluaw_t *nw;                 /* NCLua state */
  gchar *file;                  /* path to script file */
  GQueue *event_queue;          /* event queue */
  GMutex event_mutex;           /* syncs access to event queue */
} GstNCLua;

/* GstNCLua element properties.  */
enum
{
  PROPERTY_0,
  PROPERTY_FILE
};

/* Template for GstNCLua source pad.  */
static GstStaticPadTemplate gst_nclua_src_template =
GST_STATIC_PAD_TEMPLATE ("src", GST_PAD_SRC, GST_PAD_ALWAYS,
                         GST_STATIC_CAPS (GST_VIDEO_CAPS_MAKE
                                          ("{BGRA, BGRx}")));

/* Defines a GType for GstNCLua elements.  */
GType gst_nclua_get_type (void);
#define gst_nclua_parent_class parent_class
/* *INDENT-OFF* */
G_DEFINE_TYPE (GstNCLua, gst_nclua, GST_TYPE_PUSH_SRC)
/* *INDENT-ON* */

/* Defines a debug category for the NCLua plugin.  */
GST_DEBUG_CATEGORY_STATIC (nclua_debug);
#define GST_CAT_DEFAULT nclua_debug

/* Gets the GType associated with GstNCLua.  */
#define GST_TYPE_NCLUA\
  (gst_nclua_get_type ())

/* Casts OBJ to GstNCLua.  */
#define GST_NCLUA(obj)\
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GST_TYPE_NCLUA, GstNCLua))

/* Maps GstNavigation key name to its internal NCLua name.  */
typedef struct _GstNCLuaKeyMap
{
  const gchar *from;
  const gchar *to;
} GstNCLuaKeyMap;

static const GstNCLuaKeyMap gst_nclua_key_map[] = {
  /* KEEP THIS SORTED ALPHABETICALLY */
  {"Down", "CURSOR_DOWN"},
  {"Left", "CURSOR_LEFT"},
  {"Return", "ENTER"},
  {"Right", "CURSOR_RIGHT"},
  {"Up", "CURSOR_UP"},
};

static ATTR_PURE int
gst_nclua_key_map_compar (const void *p1, const void *p2)
{
  const GstNCLuaKeyMap *k1 = (const GstNCLuaKeyMap *) p1;
  const GstNCLuaKeyMap *k2 = (const GstNCLuaKeyMap *) p2;
  return strcmp (k1->from, k2->from);
}

/* Returns the internal mapping of key FROM. */

static const gchar *
gst_nclua_key_map_index (const gchar *from)
{
  GstNCLuaKeyMap key;
  GstNCLuaKeyMap *match;

  key.from = from;
  match = (GstNCLuaKeyMap *)
    bsearch (&key, gst_nclua_key_map, nelementsof (gst_nclua_key_map),
             sizeof (*gst_nclua_key_map), gst_nclua_key_map_compar);

  if (match != NULL)
    return match->to;

  return (from[0] != '\0' && from[1] != '\0')
    ? g_ascii_strup (from, -1) : from;
}

/* Forward declarations: */
static void gst_nclua_get_property (GObject *, guint, GValue *,
                                    GParamSpec *);
static void gst_nclua_set_property (GObject *, guint, const GValue *,
                                    GParamSpec *);
static GstFlowReturn gst_nclua_fill (GstPushSrc *, GstBuffer *);
static gboolean gst_nclua_event (GstBaseSrc *, GstEvent *);
static GstCaps *gst_nclua_fixate (GstBaseSrc *, GstCaps *);
static gboolean gst_nclua_set_caps (GstBaseSrc *, GstCaps *);
static gboolean gst_nclua_start (GstBaseSrc *);
static gboolean gst_nclua_stop (GstBaseSrc *);

/* Initializes GstNCLua class CLS.  */

static void
gst_nclua_class_init (GstNCLuaClass *cls)
{
  GObjectClass *gobject_class;
  GstElementClass *gstelement_class;
  GstBaseSrcClass *gstbasesrc_class;
  GstPushSrcClass *gstpushsrc_class;

  gobject_class = G_OBJECT_CLASS (cls);
  gstelement_class = GST_ELEMENT_CLASS (cls);
  gstbasesrc_class = GST_BASE_SRC_CLASS (cls);
  gstpushsrc_class = GST_PUSH_SRC_CLASS (cls);

  gobject_class->get_property = gst_nclua_get_property;
  gobject_class->set_property = gst_nclua_set_property;

  g_object_class_install_property
    (gobject_class, PROPERTY_FILE,
     g_param_spec_string
     ("file", "File", "Path to NCLua script", NULL,
      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)));

  gst_element_class_set_static_metadata
    (gstelement_class,
     "NCLua source", "Source/Video",
     "Create a video stream from an NCLua script",
     "Guilherme F. Lima <gflima@telemidia.puc-rio.br>");

  gst_element_class_add_pad_template
    (gstelement_class,
     gst_static_pad_template_get (&gst_nclua_src_template));

  gstbasesrc_class->event = gst_nclua_event;
  gstbasesrc_class->fixate = gst_nclua_fixate;
  gstbasesrc_class->set_caps = gst_nclua_set_caps;
  gstbasesrc_class->start = gst_nclua_start;
  gstbasesrc_class->stop = gst_nclua_stop;
  gstpushsrc_class->fill = gst_nclua_fill;
}

/* Initialize GstNCLua instance NCLUA.  */

static void
gst_nclua_init (GstNCLua *nclua)
{
  gst_video_info_init (&nclua->info);
  g_atomic_int_set (&nclua->new_info, 0);
  nclua->nw = NULL;
  nclua->file = NULL;
  gst_base_src_set_do_timestamp (GST_BASE_SRC (nclua), TRUE);
}

/* Gets property ID and stores its value into *VALUE.  */

static void
gst_nclua_get_property (GObject *obj, guint id, GValue *value,
                        GParamSpec *spec)
{
  GstNCLua *nclua = GST_NCLUA (obj);
  switch (id)
    {
    case PROPERTY_FILE:
      g_value_set_string (value, nclua->file);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, id, spec);
      break;
    }
}

/* Sets property ID to the given value.  */

static void
gst_nclua_set_property (GObject *obj, guint id, const GValue *value,
                        GParamSpec *spec)
{
  GstNCLua *nclua = GST_NCLUA (obj);
  switch (id)
    {
    case PROPERTY_FILE:
      g_free (nclua->file);
      nclua->file = g_value_dup_string (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, id, spec);
      break;
    }
}

/* Captures navigation events and pushes them into the input event queue.
   (Inherited from GstBaseSrc.)  */

static gboolean
gst_nclua_event (GstBaseSrc *basesrc, GstEvent *evt)
{
  if (GST_EVENT_TYPE (evt) == GST_EVENT_NAVIGATION)
    {
      GstNCLua *nclua;
      GstEvent *dup;

      nclua = GST_NCLUA (basesrc);
      dup = gst_event_copy (evt);
      g_assert (dup != NULL);
      g_mutex_lock (&nclua->event_mutex);
      g_queue_push_tail (nclua->event_queue, dup);
      g_mutex_unlock (&nclua->event_mutex);
    }

  return GST_BASE_SRC_CLASS (parent_class)->event (basesrc, evt);
}

/* Fixates the new caps CAPS.
   (Inherited from GstBaseSrc.)  */

static GstCaps *
gst_nclua_fixate (GstBaseSrc *basesrc, GstCaps *caps)
{
  GstNCLua *nclua;
  GstStructure *st;

  nclua = GST_NCLUA (basesrc);
  caps = gst_caps_make_writable (caps);
  st = gst_caps_get_structure (caps, 0);
  gst_structure_fixate_field_nearest_int (st, "width", 800);
  gst_structure_fixate_field_nearest_int (st, "height", 600);
  gst_structure_fixate_field_nearest_fraction (st, "framerate", 30, 1);

  GST_DEBUG_OBJECT (nclua, "fixating caps: %s", gst_caps_to_string (caps));

  return GST_BASE_SRC_CLASS (parent_class)->fixate (basesrc, caps);
}

/* Sets a new caps.
   (Inherited from GstBaseSrc.)  */

static gboolean
gst_nclua_set_caps (GstBaseSrc *basesrc, GstCaps *caps)
{
  GstNCLua *nclua;

  nclua = GST_NCLUA (basesrc);
  g_assert (gst_video_info_from_caps (&nclua->info, caps));
  g_atomic_int_set (&nclua->new_info, 1);

  GST_DEBUG_OBJECT (nclua, "new caps: %s\n", gst_caps_to_string (caps));

  return TRUE;
}

/* Starts the given element.
   (Inherited from GstBaseSrc.)  */

static gboolean
gst_nclua_start (GstBaseSrc *basesrc)
{
  GstNCLua *nclua;
  ncluaw_t *nw;
  char *errmsg;

  gchar *dirname;
  gchar *basename;

  nclua = GST_NCLUA (basesrc);
  g_assert (nclua->nw == NULL);
  if (unlikely (nclua->file == NULL))
    {
      GST_ELEMENT_ERROR (nclua, RESOURCE, NOT_FOUND, (NULL),
                         ("File property is not set"));
      return FALSE;
    }

  dirname = g_path_get_dirname (nclua->file);
  basename = g_path_get_basename (nclua->file);
  g_assert (dirname != NULL);
  g_assert (basename != NULL);

  /* FIXME: This can fail if dirname is invalid.  */
  g_assert (g_chdir (dirname) == 0);

  nw = ncluaw_open (basename, 800, 600, &errmsg);
  g_free (dirname);
  g_free (basename);
  if (unlikely (nw == NULL))
    {
      GST_ELEMENT_ERROR (nclua, LIBRARY, INIT, (NULL), ("%s", errmsg));
      g_free (errmsg);
      return FALSE;
    }
  /* ncluaw_at_panic (nw, gst_nclua_panic); */
  ncluaw_send_ncl_event (nw, "presentation", "start", "", NULL);
  nclua->nw = nw;

  nclua->event_queue = g_queue_new ();
  g_assert (nclua->event_queue != NULL);
  g_mutex_init (&nclua->event_mutex);

  GST_DEBUG_OBJECT (nclua, "nclua started");

  return TRUE;
}

/* Stops the given element.
   (Inherited from GstBaseSrc.)  */

static gboolean
gst_nclua_stop (GstBaseSrc *basesrc)
{
  GstNCLua *nclua;

  nclua = GST_NCLUA (basesrc);
  g_assert (nclua->nw != NULL);
  ncluaw_close (nclua->nw);
  nclua->nw = NULL;
  g_queue_free_full (nclua->event_queue, (GDestroyNotify) gst_event_unref);
  nclua->event_queue = NULL;
  g_mutex_clear (&nclua->event_mutex);

  GST_DEBUG_OBJECT (nclua, "nclua stopped");

  return TRUE;
}

/* Fills buffer with the current frame.
   (Inherited from GstPushSrc.)  */

static GstFlowReturn
gst_nclua_fill (GstPushSrc *pushsrc, GstBuffer *buf)
{
  GstNCLua *nclua;
  ncluaw_t *nw;
  GstVideoFrame frame;
  gboolean status;
  guint limit = 32;             /* max input events per cycle */

  GstVideoFormat format;
  const gchar *format_str;
  gpointer data;
  int width;
  int height;
  int stride;

  nclua = GST_NCLUA (pushsrc);
  nw = nclua->nw;

  g_mutex_lock (&nclua->event_mutex);
  while (!g_queue_is_empty (nclua->event_queue) && limit-- > 0)
    {
      GstEvent *evt;
      GstNavigationEventType type;

      evt = (GstEvent *) g_queue_pop_head (nclua->event_queue);
      g_mutex_unlock (&nclua->event_mutex);

      type = gst_navigation_event_get_type (evt);
      switch (type)
        {
        case GST_NAVIGATION_EVENT_KEY_PRESS:
        case GST_NAVIGATION_EVENT_KEY_RELEASE:
          {
            const gchar *key;
            if (likely (gst_navigation_event_parse_key_event (evt, &key)))
              {
                key = gst_nclua_key_map_index (key);
                ncluaw_send_key_event
                  (nw, (type == GST_NAVIGATION_EVENT_KEY_PRESS)
                   ? "press" : "release", key);
              }
            break;
          }
        case GST_NAVIGATION_EVENT_MOUSE_BUTTON_PRESS:
        case GST_NAVIGATION_EVENT_MOUSE_BUTTON_RELEASE:
          {
            gdouble x, y;
            if (likely (gst_navigation_event_parse_mouse_button_event
                        (evt, NULL, &x, &y)))
              {
                ncluaw_send_pointer_event
                  (nw, (type == GST_NAVIGATION_EVENT_MOUSE_BUTTON_PRESS)
                   ? "press" : "release", (int) x, (int) y);
              }
            break;
          }
        case GST_NAVIGATION_EVENT_MOUSE_MOVE:
          {
            gdouble x, y;
            if (likely (gst_navigation_event_parse_mouse_move_event
                        (evt, &x, &y)))
              {
                ncluaw_send_pointer_event (nw, "move", (int) x, (int) y);
              }
            break;
          }
        default:
          break;                /* unknown event */
        }

      gst_event_unref (evt);
      g_mutex_lock (&nclua->event_mutex);
    }
  g_mutex_unlock (&nclua->event_mutex);

  ncluaw_cycle (nw);

  status = gst_video_frame_map (&frame, &nclua->info, buf, GST_MAP_WRITE);
  if (unlikely (!status))
    {
      GST_DEBUG_OBJECT (nclua, "invalid buffer");
      return GST_FLOW_OK;
    }

  format = GST_VIDEO_FRAME_FORMAT (&frame);
  data = GST_VIDEO_FRAME_PLANE_DATA (&frame, 0);
  width = GST_VIDEO_FRAME_WIDTH (&frame);
  height = GST_VIDEO_FRAME_HEIGHT (&frame);
  stride = GST_VIDEO_FRAME_PLANE_STRIDE (&frame, 0);

  if (g_atomic_int_compare_and_exchange (&nclua->new_info, 1, 0))
    {
      gchar *w;
      gchar *h;

      ncluaw_resize (nw, width, height);
      w = g_strdup_printf ("%d", width);
      h = g_strdup_printf ("%d", height);
      ncluaw_send_ncl_event (nw, "attribution", "start", "width", w);
      ncluaw_send_ncl_event (nw, "attribution", "stop", "width", w);
      ncluaw_send_ncl_event (nw, "attribution", "start", "height", h);
      ncluaw_send_ncl_event (nw, "attribution", "stop", "height", h);
      g_free (w);
      g_free (h);

      GST_DEBUG_OBJECT (nclua, "resizing canvas to %dx%d", width, height);
    }

  switch (format)
    {
    case GST_VIDEO_FORMAT_BGRA:
      format_str = "ARGB32";
      break;
    case GST_VIDEO_FORMAT_BGRx:
      format_str = "RGB24";
      break;
    default:
      GST_DEBUG_OBJECT (nclua, "invalid format: %s",
                        gst_video_format_to_string (format));
      goto done;
    }

  ncluaw_paint (nw, (unsigned char *) data, format_str,
                width, height, stride);

 done:
  gst_video_frame_unmap (&frame);
  return GST_FLOW_OK;
}

/* Initializes the GstNCLua plugin.  */

static gboolean
nclua_init (GstPlugin *nclua)
{
  GST_DEBUG_CATEGORY_INIT (nclua_debug, "nclua", 0, PACKAGE_NAME);
  return gst_element_register (nclua, "nclua",
                               GST_RANK_NONE, GST_TYPE_NCLUA);
}

/* Plugin definition.  */
/* FIXME: Define PACKAGE_LICENSE via config.h.  */
/* *INDENT-OFF* */
#define PACKAGE PACKAGE_NAME
PRAGMA_DIAGNOSTIC_PUSH ()
PRAGMA_DIAGNOSTIC_IGNORE (-Wcast-qual)
GST_PLUGIN_DEFINE (GST_VERSION_MAJOR, GST_VERSION_MINOR, nclua,
                   "Creates a video stream from an NCLua script",
                   nclua_init, PACKAGE_VERSION, "GPL", PACKAGE_NAME,
                   PACKAGE_URL)
PRAGMA_DIAGNOSTIC_POP ()
/* *INDENT-ON* */

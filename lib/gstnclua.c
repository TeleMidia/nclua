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
#include "gstx-macros.h"
GSTX_INCLUDE_PROLOGUE
#include <gst/base/gstpushsrc.h>
#include <gst/video/gstvideometa.h>
GSTX_INCLUDE_EPILOGUE
/* *INDENT-ON* */

#include "nclua.h"
#include "ncluaw.h"

#include "macros.h"
#include "luax-macros.h"

/* Class data.  */
typedef struct _GstNCLuaClass
{
  GstPushSrcClass parent_class;
} GstNCLuaClass;

/* Instance data.  */
typedef struct _GstNCLua
{
  GstPushSrc element;           /* parent element */

  /* Properties: */
  struct
  {
    gchar *file;                /* path to NCLua script */
    gint width;                 /* main canvas width in pixels */
    gint height;                /* main canvas height in pixels */
    gboolean resize;            /* resize main canvas */
    gint fps_n;                 /* target fps numerator */
    gint fps_d;                 /* target fps denominator */
  } property;

  /* Internal data: */
  ncluaw_t *nw;                 /* NCLua state */

  struct
  {                             /* counters */
    GstClockTime time;          /* total running time */
    guint64 frames;             /* total number of frames */
  } counters;

  struct
  {                             /* video format */
    const gchar *format;        /* pixel format */
    gint width;                 /* frame width in pixels */
    gint height;                /* frame height in pixels */
    gint stride;                /* frame stride */
    gint fps_n;                 /* fps numerator */
    gint fps_d;                 /* fps denominator */
    gboolean updated;           /* flags format updates */
  } format;

  struct
  {                             /* event queue */
    GQueue *q;                  /* queue */
    GMutex mutex;               /* syncs access to event queue */
  } queue;

} GstNCLua;

/* Element properties.  */
enum
{
  PROPERTY_0,
  PROPERTY_FILE,
  PROPERTY_WIDTH,
  PROPERTY_HEIGHT,
  PROPERTY_RESIZE,
  PROPERTY_FPS
};

/* Property defaults.  */
#define DEFAULT_FILE NULL
#define DEFAULT_WIDTH 800
#define DEFAULT_HEIGHT 600
#define DEFAULT_RESIZE TRUE
#define DEFAULT_FPS_N 30
#define DEFAULT_FPS_D 1

/* Template for source pad.  */
#define GST_NCLUA_SRC_STATIC_CAPS\
  GST_STATIC_CAPS (GST_VIDEO_CAPS_MAKE ("{BGRA, BGRx}"))
#define GST_NCLUA_SRC_TEMPL                             \
  GST_STATIC_PAD_TEMPLATE ("src",                       \
                           GST_PAD_SRC,                 \
                           GST_PAD_ALWAYS,              \
                           GST_NCLUA_SRC_STATIC_CAPS)
static GstStaticPadTemplate gst_nclua_src_template = GST_NCLUA_SRC_TEMPL;

/* Element type.  */
GType gst_nclua_get_type (void);
#define gst_nclua_parent_class parent_class
/* *INDENT-OFF* */
G_DEFINE_TYPE (GstNCLua, gst_nclua, GST_TYPE_PUSH_SRC)
/* *INDENT-ON* */

/* Gets the GType of GstNCLua.  */
#define GST_TYPE_NCLUA\
  (gst_nclua_get_type ())

/* Casts object OBJ to GstNCLua.  */
#define GST_NCLUA(obj)\
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GST_TYPE_NCLUA, GstNCLua))

/* Debug category.  */
GST_DEBUG_CATEGORY_STATIC (nclua_debug);
#define GST_CAT_DEFAULT nclua_debug
#define debug GST_DEBUG_OBJECT

/**************************** Property access *****************************/

#define gst_nclua_property_init(nclua)          \
  STMT_BEGIN                                    \
  {                                             \
    (nclua)->property.file = DEFAULT_FILE;      \
    (nclua)->property.width = DEFAULT_WIDTH;    \
    (nclua)->property.height = DEFAULT_HEIGHT;  \
    (nclua)->property.resize = DEFAULT_RESIZE;  \
    (nclua)->property.fps_n = DEFAULT_FPS_N;    \
    (nclua)->property.fps_d = DEFAULT_FPS_D;    \
  }                                             \
  STMT_END

/* *INDENT-OFF* */
#define GST_NCLUA_DEFUN_SCALAR_ACCESS(Name, Type)                       \
  static Type                                                           \
  CONCAT (gst_nclua_get_property_, Name) (GstNCLua *nclua)              \
  {                                                                     \
    Type Name;                                                          \
    GST_OBJECT_LOCK (nclua);                                            \
    Name = nclua->property.Name;                                        \
    GST_OBJECT_UNLOCK (nclua);                                          \
    return Name;                                                        \
  }                                                                     \
  static void                                                           \
  CONCAT (gst_nclua_set_property_, Name) (GstNCLua *nclua, Type Name)   \
  {                                                                     \
    GST_OBJECT_LOCK (nclua);                                            \
    nclua->property.Name = Name;                                        \
    GST_OBJECT_UNLOCK (nclua);                                          \
  }

GST_NCLUA_DEFUN_SCALAR_ACCESS (width, gint)
GST_NCLUA_DEFUN_SCALAR_ACCESS (height, gint)
GST_NCLUA_DEFUN_SCALAR_ACCESS (resize, gboolean)
/* *INDENT-ON* */

static const gchar *
gst_nclua_get_property_file (GstNCLua *nclua)
{
  const gchar *file;
  GST_OBJECT_LOCK (nclua);
  file = nclua->property.file;
  GST_OBJECT_UNLOCK (nclua);
  return file;
}

static void
gst_nclua_set_property_file (GstNCLua *nclua, gchar *file)
{
  GST_OBJECT_LOCK (nclua);
  g_free (nclua->property.file);
  nclua->property.file = file;
  GST_OBJECT_UNLOCK (nclua);
}

static void
gst_nclua_get_property_fps (GstNCLua *nclua, gint *fps_n, gint *fps_d)
{
  GST_OBJECT_LOCK (nclua);
  set_if_nonnull (fps_n, nclua->property.fps_n);
  set_if_nonnull (fps_d, nclua->property.fps_d);
  GST_OBJECT_UNLOCK (nclua);
}

static void
gst_nclua_set_property_fps (GstNCLua *nclua, gint fps_n, gint fps_d)
{
  GST_OBJECT_LOCK (nclua);
  nclua->property.fps_n = fps_n;
  nclua->property.fps_d = fps_d;
  GST_OBJECT_UNLOCK (nclua);
}

/************************** Internal data access **************************/

/* Initializes internal data of element NCLUA.  */

static void
gst_nclua_internal_init (GstNCLua *nclua)
{
  GST_OBJECT_LOCK (nclua);
  nclua->nw = NULL;
  nclua->format.format = NULL;
  nclua->format.width = 0;
  nclua->format.height = 0;
  nclua->format.stride = 0;
  nclua->format.fps_n = 0;
  nclua->format.fps_d = 0;
  nclua->format.updated = FALSE;
  nclua->queue.q = g_queue_new ();
  g_assert (nclua->queue.q != NULL);    /* cannot fail */
  g_mutex_init (&nclua->queue.mutex);
  GST_OBJECT_UNLOCK (nclua);
}

/* Finalizes internal data of element NCLUA.  */

static void
gst_nclua_internal_fini (GstNCLua *nclua)
{
  GST_OBJECT_LOCK (nclua);
  ncluaw_close (nclua->nw);
  g_queue_free_full (nclua->queue.q, (GDestroyNotify) gst_event_unref);
  g_mutex_clear (&nclua->queue.mutex);
  GST_OBJECT_UNLOCK (nclua);
}

/* Gets the time and frame counters of element NCLUA and stores them into
   *TIME and *FRAMES, respectively.  */

static void
gst_nclua_get_counters (GstNCLua *nclua, GstClockTime *time,
                        guint64 *frames)
{
  GST_OBJECT_LOCK (nclua);
  set_if_nonnull (time, nclua->counters.time);
  set_if_nonnull (frames, nclua->counters.frames);
  GST_OBJECT_UNLOCK (nclua);
}

/* Sets the time and frame counters of element NCLUA to TIME and FRAME,
   respectively.  */

static void
gst_nclua_set_counters (GstNCLua *nclua, GstClockTime time, guint64 frames)
{
  GST_OBJECT_LOCK (nclua);
  nclua->counters.time = time;
  nclua->counters.frames = frames;
  GST_OBJECT_UNLOCK (nclua);
}

/* Gets the format parameters of element NCLUA and stores them into *FORMAT,
   *WIDTH, *HEIGHT, *STRIDE, *FPS_N, and *FPS_D.

   Returns the value of the updated flag; if RESET_UPDATED is TRUE then
   resets updated flag.  */

static gboolean
gst_nclua_get_format (GstNCLua *nclua, const gchar **format,
                      gint *width, gint *height, gint *stride,
                      gint *fps_n, gint *fps_d, gboolean reset_updated)
{
  gboolean result;

  GST_OBJECT_LOCK (nclua);
  set_if_nonnull (format, nclua->format.format);
  set_if_nonnull (width, nclua->format.width);
  set_if_nonnull (height, nclua->format.height);
  set_if_nonnull (stride, nclua->format.stride);
  set_if_nonnull (fps_n, nclua->format.fps_n);
  set_if_nonnull (fps_d, nclua->format.fps_d);
  result = nclua->format.updated;
  if (reset_updated)
    nclua->format.updated = FALSE;
  GST_OBJECT_UNLOCK (nclua);

  return result;
}

/* Sets the format parameters of element NCLUA to the given FORMAT, WIDTH,
   HEIGHT, STRIDE, FPS_N, and FPS_D values; and sets the updated flag to
   true.  */

static void
gst_nclua_set_format (GstNCLua *nclua, const gchar *format,
                      gint width, gint height, gint stride,
                      gint fps_n, gint fps_d)
{
  GST_OBJECT_LOCK (nclua);
  nclua->format.format = format;
  nclua->format.width = width;
  nclua->format.height = height;
  nclua->format.stride = stride;
  nclua->format.fps_n = fps_n;
  nclua->format.fps_d = fps_d;
  nclua->format.updated = TRUE;
  GST_OBJECT_UNLOCK (nclua);
}

/* Enqueues event EVT into event queue of element NCLUA.
   Returns true if successful, otherwise returns false.  */

static void
gst_nclua_enqueue_event (GstNCLua *nclua, GstEvent *evt)
{
  g_mutex_lock (&nclua->queue.mutex);
  g_queue_push_tail (nclua->queue.q, evt);
  g_mutex_unlock (&nclua->queue.mutex);
}

/* Dequeues an event from element NCLUA's event queue and stores it in *EVT.
   Returns true if successful; returns false if no element could be
   popped (queue is empty).  */

static gboolean
gst_nclua_dequeue_event (GstNCLua *nclua, GstEvent **evt)
{
  GstEvent *tmp;

  g_mutex_lock (&nclua->queue.mutex);
  tmp = (GstEvent *) g_queue_pop_head (nclua->queue.q);
  g_mutex_unlock (&nclua->queue.mutex);

  if (tmp == NULL)
    return FALSE;

  set_if_nonnull (evt, tmp);
  return TRUE;
}

/************** Conversion of GstNavigation to NCLua events ***************/

typedef struct _GstNCLuaKeyMap
{
  const gchar *from;
  const gchar *to;
} GstNCLuaKeyMap;

/* Maps a navigation key name into its internal key name.  */
static const GstNCLuaKeyMap gst_nclua_keymap[] = {
  /* KEEP THIS SORTED ALPHABETICALLY */
  {"Down", "CURSOR_DOWN"},
  {"Left", "CURSOR_LEFT"},
  {"Return", "ENTER"},
  {"Right", "CURSOR_RIGHT"},
  {"Up", "CURSOR_UP"},
};

static ATTR_PURE int
gst_nclua_keymap_compar (const void *p1, const void *p2)
{
  const GstNCLuaKeyMap *k1 = (const GstNCLuaKeyMap *) p1;
  const GstNCLuaKeyMap *k2 = (const GstNCLuaKeyMap *) p2;
  return strcmp (k1->from, k2->from);
}

/* Returns the internal mapping of key FROM. */

static const gchar *
gst_nclua_keymap_index (const gchar *from)
{
  GstNCLuaKeyMap key;
  GstNCLuaKeyMap *match;

  key.from = from;
  match = (GstNCLuaKeyMap *)
    bsearch (&key, gst_nclua_keymap, nelementsof (gst_nclua_keymap),
             sizeof (*gst_nclua_keymap), gst_nclua_keymap_compar);

  if (match != NULL)
    return match->to;

  return (from[0] != '\0' && from[1] != '\0')
    ? g_ascii_strup (from, -1) : from;
}

/* Converts navigation event type TYPE to NCLua type.  */

static const gchar *
gst_nclua_navigation_convert_type (GstNavigationEventType type)
{
  switch (type)
    {
    case GST_NAVIGATION_EVENT_KEY_PRESS:
    case GST_NAVIGATION_EVENT_MOUSE_BUTTON_PRESS:
      return "press";
    case GST_NAVIGATION_EVENT_KEY_RELEASE:
    case GST_NAVIGATION_EVENT_MOUSE_BUTTON_RELEASE:
      return "release";
    case GST_NAVIGATION_EVENT_MOUSE_MOVE:
      return "move";
    default:
      ASSERT_NOT_REACHED;
    }
}

/* Converts navigation event FROM into an equivalent NCLua event.  If
   successful, allocates and stores the resulting event into *TO and returns
   true; otherwise returns false.  */

static gboolean
gst_nclua_navigation_convert (GstEvent *from, ncluaw_event_t **to)
{
  GstNavigationEventType type;
  ncluaw_event_t evt;

  const gchar *key;
  const gchar *type_str;
  gdouble x, y;

  type = gst_navigation_event_get_type (from);
  switch (type)
    {
    case GST_NAVIGATION_EVENT_KEY_PRESS:
    case GST_NAVIGATION_EVENT_KEY_RELEASE:
      if (unlikely (!gst_navigation_event_parse_key_event (from, &key)))
        {
          return FALSE;
        }
      key = gst_nclua_keymap_index (key);
      type_str = gst_nclua_navigation_convert_type (type);
      ncluaw_event_key_init (&evt, type_str, key);
      break;

    case GST_NAVIGATION_EVENT_MOUSE_BUTTON_PRESS:
    case GST_NAVIGATION_EVENT_MOUSE_BUTTON_RELEASE:
      if (unlikely (!gst_navigation_event_parse_mouse_button_event
                    (from, NULL, &x, &y)))
        {
          return FALSE;
        }
      type_str = gst_nclua_navigation_convert_type (type);
      ncluaw_event_pointer_init (&evt, type_str, (int) x, (int) y);
      break;

    case GST_NAVIGATION_EVENT_MOUSE_MOVE:
      if (!unlikely (gst_navigation_event_parse_mouse_move_event
                     (from, &x, &y)))
        {
          return FALSE;
        }
      type_str = gst_nclua_navigation_convert_type (type);
      ncluaw_event_pointer_init (&evt, type_str, (int) x, (int) y);
      break;

    default:
      return FALSE;             /* unknown type */
    }

  set_if_nonnull (to, ncluaw_event_clone (&evt));
  return TRUE;
}

/************************** Custom NCLua events ***************************/

/* Sends a canvas resize event to state NW with the given dimensions.  */

static void
gst_nclua_send_resize_event (ncluaw_t *nw, gint width, gint height)
{
  gchar *w = g_strdup_printf ("%d", width);
  gchar *h = g_strdup_printf ("%d", height);
  ncluaw_resize (nw, width, height);
  ncluaw_send_ncl_event (nw, "attribution", "start", "width", w);
  ncluaw_send_ncl_event (nw, "attribution", "stop", "width", w);
  ncluaw_send_ncl_event (nw, "attribution", "start", "height", h);
  ncluaw_send_ncl_event (nw, "attribution", "stop", "height", h);
  g_free (w);
  g_free (h);
}

/* Sends a tick event to state NW with the given parameters.  */

static void
gst_nclua_send_tick_event (ncluaw_t *nw, guint64 frames,
                           GstClockTime abs, GstClockTime rel,
                           GstClockTime diff)
{
  lua_State *L = (lua_State *) ncluaw_debug_get_lua_state (nw);
  lua_newtable (L);
  luax_setstringfield (L, -1, "class", "tick");
  luax_setnumberfield (L, -1, "frame", (lua_Number) (frames));
  luax_setnumberfield (L, -1, "absolute", (lua_Number) (abs) / 1000);
  luax_setnumberfield (L, -1, "relative", (lua_Number) (rel) / 1000);
  luax_setnumberfield (L, -1, "diff", (lua_Number) (diff) / 1000);
  nclua_send (L);
}

/******************************* GstPushSrc *******************************/

/* Fills buffer BUF with the current frame.
   TODO: Document return values.  */

static GstFlowReturn
gst_nclua_fill (GstPushSrc *pushsrc, GstBuffer *buf)
{
  GstNCLua *nclua;
  ncluaw_t *nw;

  GstEvent *evt;
  guint limit = 32;             /* max input events per cycle */

  GstMapInfo map;
  gboolean updated;
  const gchar *format;
  gint width, height, stride, fps_n, fps_d;

  GstClockTime time;
  guint64 frames;

  nclua = GST_NCLUA (pushsrc);
  nw = nclua->nw;

  /* Process pending events.  */
  while (gst_nclua_dequeue_event (nclua, &evt) && limit-- > 0)
    {
      ncluaw_event_t *e;
      switch (GST_EVENT_TYPE (evt))
        {
        case GST_EVENT_NAVIGATION:     /* send event to nclua  */
          if (likely (gst_nclua_navigation_convert (evt, &e)))
            {
              ncluaw_send (nw, e);
              ncluaw_event_free (e);
            }
        default:
          break;                /* nothing to do */
        }
      gst_event_unref (evt);
    }

  /* Cycle the NCLua engine once.  */
  ncluaw_cycle (nw);

  /* Get format.  */
  updated = gst_nclua_get_format (nclua, &format, &width, &height, &stride,
                                  &fps_n, &fps_d, TRUE);
  if (unlikely (format == NULL))
    return GST_FLOW_NOT_NEGOTIATED;

  /* Get counters.  */
  gst_nclua_get_counters (nclua, &time, &frames);
  if (unlikely (fps_n == 0 && frames == 1))
    return GST_FLOW_EOS;

  /* Resize canvas, if format was updated.  */
  if (updated && gst_nclua_get_property_resize (nclua))
    gst_nclua_send_resize_event (nw, width, height);

  /* Paint canvas onto buffer.  */
  if (unlikely (!gst_buffer_map (buf, &map, GST_MAP_WRITE)))
    {
      debug (nclua, "invalid buffer");
      return GST_FLOW_OK;
    }
  ncluaw_paint (nw, map.data, format, width, height, stride);
  gst_buffer_unmap (buf, &map);

  /* Set buffer timing.  */
  GST_BUFFER_DTS (buf) = time;
  GST_BUFFER_PTS (buf) = GST_BUFFER_DTS (buf);
  gst_object_sync_values (GST_OBJECT (nclua), GST_BUFFER_DTS (buf));
  GST_BUFFER_OFFSET (buf) = frames++;
  GST_BUFFER_OFFSET_END (buf) = GST_BUFFER_OFFSET (buf) + 1;

  if (fps_n > 0)
    {
      GstClockTime next;
      next = gst_util_uint64_scale_int (frames * GST_SECOND, fps_d, fps_n);
      GST_BUFFER_DURATION (buf) = next - time;
      time = next;
    }
  else
    {
      time = 0;
      GST_BUFFER_DURATION (buf) = GST_CLOCK_TIME_NONE;  /* forever */
    }

  /* Update counters.  */
  gst_nclua_set_counters (nclua, time, frames);

  /* Send tick event.  */
  gst_nclua_send_tick_event (nclua->nw, frames,
                             time, time, GST_BUFFER_DURATION (buf));

  return GST_FLOW_OK;
}

/******************************* GstBaseSrc *******************************/

/* Handles events on source pad.  */

static gboolean
gst_nclua_event (GstBaseSrc *basesrc, GstEvent *evt)
{
  GstNCLua *nclua = GST_NCLUA (basesrc);
  switch (GST_EVENT_TYPE (evt))
    {
    case GST_EVENT_NAVIGATION: /* push event into event queue */
      gst_nclua_enqueue_event (nclua, gst_event_ref (evt));
      break;
    default:                   /* nothing to do */
      break;
    }
  return GST_BASE_SRC_CLASS (parent_class)->event (basesrc, evt);
}

/* Fixates caps CAPS.
   TODO: Move hard-coded stuff to macros.  */

static GstCaps *
gst_nclua_fixate (GstBaseSrc *basesrc, GstCaps *caps)
{
  GstNCLua *nclua;
  GstStructure *st;
  gint width, height, fps_n, fps_d;

  nclua = GST_NCLUA (basesrc);
  caps = gst_caps_make_writable (caps);
  st = gst_caps_get_structure (caps, 0);

  width = gst_nclua_get_property_width (nclua);
  height = gst_nclua_get_property_height (nclua);
  gst_nclua_get_property_fps (nclua, &fps_n, &fps_d);

  if (gst_nclua_get_property_resize (nclua))
    {
      gst_structure_fixate_field_nearest_int (st, "width", width);
      gst_structure_fixate_field_nearest_int (st, "height", height);
    }
  else
    {
      GValue value = G_VALUE_INIT;
      g_value_init (&value, G_TYPE_INT);
      g_value_set_int (&value, width);
      gst_structure_set_value (st, "width", &value);
      g_value_set_int (&value, height);
      gst_structure_set_value (st, "height", &value);
    }

  gst_structure_fixate_field_nearest_fraction (st, "framerate",
                                               fps_n, fps_d);

  debug (nclua, "fixating caps: %" GST_PTR_FORMAT, (void *) caps);

  return GST_BASE_SRC_CLASS (parent_class)->fixate (basesrc, caps);
}

/* Sets caps CAPS on source pad.
   Returns TRUE if successful, otherwise returns false.  */

static gboolean
gst_nclua_set_caps (GstBaseSrc *basesrc, GstCaps *caps)
{
  GstNCLua *nclua;
  GstVideoInfo info;
  const gchar *format;
  gint width, height, stride, fps_n, fps_d;

  nclua = GST_NCLUA (basesrc);
  if (unlikely (!gst_video_info_from_caps (&info, caps)))
    goto fail_bad_caps;

  switch (GST_VIDEO_INFO_FORMAT (&info))
    {
    case GST_VIDEO_FORMAT_BGRA:
      format = "ARGB32";
      break;
    case GST_VIDEO_FORMAT_BGRx:
      format = "RGB24";
      break;
    default:
      goto fail_unsupported_caps;
    }
  width = GST_VIDEO_INFO_WIDTH (&info);
  height = GST_VIDEO_INFO_HEIGHT (&info);
  stride = GST_VIDEO_INFO_PLANE_STRIDE (&info, 0);
  fps_n = info.fps_n;
  fps_d = info.fps_d;

  gst_nclua_set_format (nclua, format, width, height, stride, fps_n, fps_d);
  debug (nclua, "new caps: %" GST_PTR_FORMAT, (void *) caps);

  return TRUE;

 fail_bad_caps:
  debug (nclua, "cannot parse caps: %" GST_PTR_FORMAT, (void *) caps);
  return FALSE;

 fail_unsupported_caps:
  debug (nclua, "unsupported caps: %" GST_PTR_FORMAT, (void *) caps);
  return FALSE;
}

/* Starts the given element.
   Returns true if successful, otherwise returns false.  */

static gboolean
gst_nclua_start (GstBaseSrc *basesrc)
{
  GstNCLua *nclua;
  ncluaw_t *nw;

  const gchar *file;
  gchar *dirname;
  gchar *basename;
  gchar *errmsg;
  gint width, height;

  nclua = GST_NCLUA (basesrc);
  file = gst_nclua_get_property_file (nclua);
  if (unlikely (file == NULL))
    {
      GST_ELEMENT_ERROR (nclua, RESOURCE, NOT_FOUND, (NULL),
                         ("File property is not set"));
      return FALSE;
    }

  /* Allocates the NCLua state.  */
  dirname = g_path_get_dirname (file);
  basename = g_path_get_basename (file);
  g_assert (dirname != NULL);
  g_assert (basename != NULL);

  if (unlikely (g_chdir (dirname) != 0))
    {
      GST_ELEMENT_ERROR (nclua, RESOURCE, NOT_FOUND, (NULL),
                         ("Cannot cd into %s", dirname));
      g_free (dirname);
      g_free (basename);
      return FALSE;
    }

  width = gst_nclua_get_property_width (nclua);
  height = gst_nclua_get_property_height (nclua);
  nw = ncluaw_open (basename, width, height, &errmsg);
  g_free (dirname);
  g_free (basename);
  if (unlikely (nw == NULL))
    {
      GST_ELEMENT_ERROR (nclua, LIBRARY, INIT, (NULL), ("%s", errmsg));
      g_free (errmsg);
      return FALSE;
    }

  ncluaw_send_ncl_event (nw, "presentation", "start", "", NULL);

  /* Initialize element's internal data.  */
  gst_nclua_internal_init (nclua);
  nclua->nw = nw;

  debug (nclua, "nclua started");

  return TRUE;
}

/* Stops the given element.  */

static gboolean
gst_nclua_stop (GstBaseSrc *basesrc)
{
  GstNCLua *nclua = GST_NCLUA (basesrc);
  gst_nclua_internal_fini (nclua);
  debug (nclua, "nclua stopped");
  return TRUE;
}

/******************************** GObject *********************************/

/* Gets property and stores its value into *VALUE.  */

static void
gst_nclua_get_property (GObject *obj, guint id, GValue *value,
                        GParamSpec *spec)
{
  GstNCLua *nclua = GST_NCLUA (obj);
  switch (id)
    {
    case PROPERTY_FILE:
      {
        const gchar *file = gst_nclua_get_property_file (nclua);
        g_value_set_string (value, file);
        break;
      }
    case PROPERTY_WIDTH:
      {
        guint width = (guint) clamp (gst_nclua_get_property_width (nclua),
                                     0, G_MAXINT);
        g_value_set_uint (value, width);
        break;
      }
    case PROPERTY_HEIGHT:
      {
        guint height = (guint) clamp (gst_nclua_get_property_height (nclua),
                                      0, G_MAXINT);
        g_value_set_uint (value, height);
        break;
      }
    case PROPERTY_RESIZE:
      {
        gboolean resize = gst_nclua_get_property_resize (nclua);
        g_value_set_boolean (value, resize);
        break;
      }
    case PROPERTY_FPS:
      {
        gint fps_n, fps_d;
        gst_nclua_get_property_fps (nclua, &fps_n, &fps_d);
        gst_value_set_fraction (value, fps_n, fps_d);
        break;
      }
    default:
      {
        G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, id, spec);
        break;
      }
    }
}

/* Sets property to the given value.  */

static void
gst_nclua_set_property (GObject *obj, guint id, const GValue *value,
                        GParamSpec *spec)
{
  GstNCLua *nclua = GST_NCLUA (obj);
  switch (id)
    {
    case PROPERTY_FILE:
      {
        gchar *file = g_value_dup_string (value);
        gst_nclua_set_property_file (nclua, file);
        break;
      }
    case PROPERTY_WIDTH:
      {
        gint width = (gint) clamp (g_value_get_uint (value), 0, G_MAXINT);
        gst_nclua_set_property_width (nclua, width);
        break;
      }
    case PROPERTY_HEIGHT:
      {
        gint height = (gint) clamp (g_value_get_uint (value), 0, G_MAXINT);
        gst_nclua_set_property_height (nclua, height);
        break;
      }
    case PROPERTY_RESIZE:
      {
        gboolean resize = g_value_get_boolean (value);
        gst_nclua_set_property_resize (nclua, resize);
        break;
      }
    case PROPERTY_FPS:
      {
        gint fps_n, fps_d;
        fps_n = gst_value_get_fraction_numerator (value);
        fps_d = gst_value_get_fraction_denominator (value);
        gst_nclua_set_property_fps (nclua, fps_n, fps_d);
        break;
      }
    default:
      {
        G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, id, spec);
        break;
      }
    }
}

/***************************** Initialization *****************************/

/* Class initializer.  */

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
     ("file", "File", "Path to NCLua script", DEFAULT_FILE,
      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property
    (gobject_class, PROPERTY_WIDTH,
     g_param_spec_uint
     ("width", "Width", "Main canvas width in pixels",
      0, G_MAXUINT, DEFAULT_WIDTH,
      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property
    (gobject_class, PROPERTY_HEIGHT,
     g_param_spec_uint
     ("height", "Height", "Main canvas height in pixels",
      0, G_MAXUINT, DEFAULT_HEIGHT,
      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property
    (gobject_class, PROPERTY_RESIZE,
     g_param_spec_boolean
     ("resize", "Resize", "Resize main canvas", DEFAULT_RESIZE,
      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)));

  g_object_class_install_property
    (gobject_class, PROPERTY_FPS,
     gst_param_spec_fraction
     ("fps", "Framerate", "Target framerate",
      0, 1, G_MAXINT, 1, DEFAULT_FPS_N, DEFAULT_FPS_D,
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

/* Instance initializer.  */

static void
gst_nclua_init (GstNCLua *nclua)
{
  gst_nclua_property_init (nclua);
  gst_base_src_set_format (GST_BASE_SRC (nclua), GST_FORMAT_TIME);
}

/* Plugin initializer.  */

static gboolean
nclua_init (GstPlugin *nclua)
{
  GST_DEBUG_CATEGORY_INIT (nclua_debug, "nclua", 0, PACKAGE_NAME);
  return gst_element_register (nclua, "nclua",
                               GST_RANK_NONE, GST_TYPE_NCLUA);
}

/* Plugin definition.  */
/* *INDENT-OFF* */
PRAGMA_DIAG_PUSH ()
PRAGMA_DIAG_IGNORE (-Wcast-qual)
GST_PLUGIN_DEFINE (GST_VERSION_MAJOR, GST_VERSION_MINOR, nclua,
                   "Creates a video stream from an NCLua script",
                   nclua_init, PACKAGE_VERSION, "GPL", PACKAGE_NAME,
                   PACKAGE_URL)
PRAGMA_DIAG_POP ()
/* *INDENT-ON* */

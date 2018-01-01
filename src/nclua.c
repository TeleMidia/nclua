/* nclua.c -- A GTK+-3.0 standalone NCLua player.
   Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <https://www.gnu.org/licenses/>.  */

#include <config.h>
#include <math.h>
#include <setjmp.h>
#include <stdlib.h>
#include <string.h>
#include "aux-glib.h"
#include "aux-lua.h"
#include <gtk/gtk.h>

#include "nclua.h"
#include "ncluaw.h"

/* Globals: */
static GtkWidget *app;
static ncluaw_t *ncluaw_state;
static jmp_buf panic_jmp;

/* Options: */
#define OPTION_LINE "FILE"
#define OPTION_DESC                             \
  "Report bugs to: " PACKAGE_BUGREPORT "\n"     \
  "NCLua home page: " PACKAGE_URL

static gboolean opt_fullscreen = FALSE; /* true if --fullscreen was given */
static gboolean opt_scale = FALSE;      /* true if --scale was given */
static gint opt_width = 800;    /* initial window width */
static gint opt_height = 600;   /* initial window height */

static gboolean
opt_size (unused (const gchar *opt), const gchar *arg,
          unused (gpointer data), GError **err)
{
  guint64 width;
  guint64 height;
  gchar *end;

  width = g_ascii_strtoull (arg, &end, 10);
  if (width == 0)
    goto syntax_error;
  opt_width = (gint) (CLAMP ((int) width, 0, G_MAXINT));

  if (*end != 'x')
    goto syntax_error;

  height = g_ascii_strtoull (++end, NULL, 10);
  if (height == 0)
    goto syntax_error;
  opt_height = (gint) (CLAMP ((int) height, 0, G_MAXINT));

  return TRUE;

 syntax_error:
  g_set_error (err, G_OPTION_ERROR, G_OPTION_ERROR_BAD_VALUE,
               "Invalid size string '%s'", arg);
  return FALSE;
}

static gboolean
opt_version (void)
{
  puts (PACKAGE_STRING);
  exit (EXIT_SUCCESS);
}

#define gpointerof(p) ((gpointer)((ptrdiff_t)(p)))
static GOptionEntry options[] = {
  {"size", 's', 0, G_OPTION_ARG_CALLBACK,
   gpointerof (opt_size), "Set initial window size", "WIDTHxHEIGHT"},
  {"fullscreen", 'S', 0, G_OPTION_ARG_NONE,
   &opt_fullscreen, "Enable full-screen mode", NULL},
  {"scale", 'x', 0, G_OPTION_ARG_NONE,
   &opt_scale, "Scale canvas to fit window", NULL},
  {"version", 0, G_OPTION_FLAG_NO_ARG, G_OPTION_ARG_CALLBACK,
   gpointerof (opt_version), "Print version information and exit", NULL},
  {NULL}
};

/* Error handling: */
#define usage_error(message) _error (TRUE, message)
#define print_error(message) _error (FALSE, message)

static void
_error (gboolean try_help, const gchar *message)
{
  const gchar *me = g_get_application_name ();
  g_fprintf (stderr, "%s: %s\n", me, message);
  if (try_help)
    g_fprintf (stderr, "Try '%s --help' for more information.\n", me);
}

static void
panic (unused (ncluaw_t *nw), const char *message)
{
  luax_dump_stack (cast (lua_State *, ncluaw_debug_get_lua_state (nw)));
  print_error (message);
  longjmp (panic_jmp, 1);
}

/* Callbacks: */
#if GTK_CHECK_VERSION(3,8,0)
static gboolean
cycle_callback (unused (GtkWidget *widget), GdkFrameClock *frame_clock,
                unused (gpointer data))
#else
static gboolean
cycle_callback (arg_unused (GtkWidget *widget))
#endif
{
  ncluaw_event_t *evt;
  lua_State *L;
  gint64 time;
  static gint64 frame = -1;
  static gint64 last;
  static gint64 first;

  L = (lua_State *) ncluaw_debug_get_lua_state (ncluaw_state);

#if GTK_CHECK_VERSION(3,8,0)
  time = gdk_frame_clock_get_frame_time (frame_clock);
  frame = gdk_frame_clock_get_frame_counter (frame_clock);
#else
  time = g_get_monotonic_time ();
  frame++;
#endif

  if (frame == 0)
    {
      first = time;
      last = time;
    }

  lua_newtable (L);
  luax_setstringfield (L, -1, "class", "tick");
  luax_setnumberfield (L, -1, "frame", (lua_Number) (frame));
  luax_setnumberfield (L, -1, "absolute", (lua_Number) (time));
  luax_setnumberfield (L, -1, "relative", (lua_Number) (time - first));
  luax_setnumberfield (L, -1, "diff", (lua_Number) (time - last));
  last = time;
  nclua_send (L);

  ncluaw_cycle (ncluaw_state);

  evt = ncluaw_receive (ncluaw_state);
  if (evt != NULL
      && evt->cls == NCLUAW_EVENT_NCL
      && g_str_equal (evt->u.ncl.type, "presentation")
      && g_str_equal (evt->u.ncl.action, "stop")
      && g_str_equal (evt->u.ncl.name, ""))
    {
      ncluaw_event_free (evt);
      gtk_widget_destroy (app);
      return G_SOURCE_REMOVE;
    }

  gtk_widget_queue_draw (app);

  return G_SOURCE_CONTINUE;
}

static gboolean
draw_callback (unused (GtkWidget *widget), cairo_t *cr,
               unused (gpointer data))
{
  cairo_surface_t *sfc;

  sfc = (cairo_surface_t *) ncluaw_debug_get_surface (ncluaw_state);
  g_assert (sfc != NULL);

  if (!opt_scale)
    {
      cairo_set_source_surface (cr, sfc, 0, 0);
      cairo_paint (cr);
    }
  else
    {
      cairo_pattern_t *pattern;
      cairo_matrix_t matrix;
      int app_w, app_h, sfc_w, sfc_h;
      double sx, sy;

      pattern = cairo_pattern_create_for_surface (sfc);
      g_assert (pattern != NULL);

      app_w = gtk_widget_get_allocated_width (app);
      app_h = gtk_widget_get_allocated_height (app);
      sfc_w = cairo_image_surface_get_width (sfc);
      sfc_h = cairo_image_surface_get_height (sfc);

      cairo_matrix_init (&matrix, 1, 0, 0, 1, 0, 0);
      sx = ((double) app_w) / ((double) sfc_w);
      sy = ((double) app_h) / ((double) sfc_h);
      cairo_matrix_scale (&matrix, 1 / sx, 1 / sy);

      cairo_pattern_set_matrix (pattern, &matrix);
      cairo_set_source (cr, pattern);
      cairo_paint (cr);
      cairo_pattern_destroy (pattern);
    }

  return TRUE;
}

static gboolean
keyboard_callback (unused (GtkWidget *widget), GdkEventKey *e,
                   gpointer type)
{
  const char *key;
  int free_key = FALSE;

  switch (e->keyval)
    {
    case GDK_KEY_Escape:       /* quit */
      gtk_widget_destroy (app);
      return TRUE;
    case GDK_KEY_F11:          /* toggle full-screen */
      if (g_str_equal ((const char *) type, "release"))
        return TRUE;
      opt_fullscreen = !opt_fullscreen;
      if (opt_fullscreen)
        gtk_window_fullscreen (GTK_WINDOW (app));
      else
        gtk_window_unfullscreen (GTK_WINDOW (app));
      return TRUE;
    case GDK_KEY_asterisk:
      key = "*";
      break;
    case GDK_KEY_numbersign:
      key = "#";
      break;
    case GDK_KEY_Return:
      key = "ENTER";
      break;
    case GDK_KEY_F1:
      key = "RED";
      break;
    case GDK_KEY_F2:
      key = "GREEN";
      break;
    case GDK_KEY_F3:
      key = "BLUE";
      break;
    case GDK_KEY_F4:
      key = "YELLOW";
      break;
    case GDK_KEY_Down:
      key = "CURSOR_DOWN";
      break;
    case GDK_KEY_Left:
      key = "CURSOR_LEFT";
      break;
    case GDK_KEY_Right:
      key = "CURSOR_RIGHT";
      break;
    case GDK_KEY_Up:
      key = "CURSOR_UP";
      break;
    default:
      key = gdk_keyval_name (e->keyval);
      if (strlen (key) > 1)
        {
          key = g_utf8_strup (key, -1);
          free_key = TRUE;
        }
      break;
    }

  ncluaw_send_key_event (ncluaw_state, (const char *) type, key);
  if (free_key)                 /* do not remove */
    g_free (deconst (char *, key));

  return TRUE;
}

static void
pointer_get_position (int x, int y, int *rx, int *ry)
{
  if (!opt_scale)
    {
      *rx = x;
      *ry = y;
    }
  else
    {
      cairo_surface_t *sfc;
      int app_w, app_h, sfc_w, sfc_h;

      app_w = gtk_widget_get_allocated_width (app);
      app_h = gtk_widget_get_allocated_height (app);

      sfc = (cairo_surface_t *) ncluaw_debug_get_surface (ncluaw_state);
      sfc_w = cairo_image_surface_get_width (sfc);
      sfc_h = cairo_image_surface_get_height (sfc);

      *rx = (int) CLAMP (lround ((x) * sfc_w / app_w), 0, sfc_w);
      *ry = (int) CLAMP (lround ((y) * sfc_h / app_h), 0, sfc_h);
    }
}

static gboolean
pointer_motion_callback (unused (GtkWidget *widget),
                         GdkEventMotion *e, unused (const char *type))
{
  int x, y;

  pointer_get_position ((int) e->x, (int) e->y, &x, &y);
  ncluaw_send_pointer_event (ncluaw_state, "move", x, y);

  return TRUE;
}

static gboolean
pointer_click_callback (unused (GtkWidget *widget), GdkEventButton *e,
                        unused (gpointer data))
{
  const char *type;
  int x, y;

  switch (e->type)
    {
    case GDK_BUTTON_PRESS:
      type = "press";
      break;
    case GDK_BUTTON_RELEASE:
      type = "release";
      break;
    default:
      return TRUE;              /* nothing to do */
    }

  pointer_get_position ((int) e->x, (int) e->y, &x, &y);
  ncluaw_send_pointer_event (ncluaw_state, type, x, y);

  return TRUE;
}

static gboolean
resize_callback (unused (GtkWidget *widget), GdkEventConfigure *e,
                 unused (gpointer data))
{
  gchar *width;
  gchar *height;

  ncluaw_resize (ncluaw_state, e->width, e->height);
  width = g_strdup_printf ("%d", e->width);
  height = g_strdup_printf ("%d", e->height);
  ncluaw_send_ncl_event (ncluaw_state, "attribution", "start",
                         "width", width);
  ncluaw_send_ncl_event (ncluaw_state, "attribution", "stop",
                         "width", width);
  ncluaw_send_ncl_event (ncluaw_state, "attribution", "start",
                         "height", height);
  ncluaw_send_ncl_event (ncluaw_state, "attribution", "stop",
                         "height", height);
  g_free (width);
  g_free (height);

  /* We must return FALSE here, otherwise the new geometry is not propagated
     to draw_callback().  */
  return FALSE;
}

int
main (int argc, char **argv)
{
  GOptionContext *ctx;
  gboolean status;
  GError *error = NULL;
  gchar *dirname;
  gchar *basename;
  char *errmsg = NULL;
  volatile int exit_status = EXIT_SUCCESS;

  gtk_init (&argc, &argv);

  /* Parse command-line options and arguments.  */
  ctx = g_option_context_new (OPTION_LINE);
  g_assert (ctx != NULL);       /* cannot fail */
  g_option_context_set_description (ctx, OPTION_DESC);
  g_option_context_add_main_entries (ctx, options, NULL);
  g_option_context_add_group (ctx, gtk_get_option_group (TRUE));
  status = g_option_context_parse (ctx, &argc, &argv, &error);
  g_option_context_free (ctx);
  if (unlikely (!status))
    {
      g_assert (error != NULL);
      usage_error (error->message);
      g_error_free (error);
      exit (EXIT_FAILURE);
    }

  if (unlikely (argc != 2))
    {
      usage_error ("Missing file operand");
      exit (EXIT_FAILURE);
    }

  /* Create application window.  */
  app = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  g_assert (app != NULL);       /* cannot fail */
  gtk_window_set_title (GTK_WINDOW (app), "NCLua");
  gtk_window_set_default_size (GTK_WINDOW (app), opt_width, opt_height);
  gtk_widget_set_app_paintable (app, TRUE);
  if (opt_fullscreen)
    gtk_window_fullscreen (GTK_WINDOW (app));

  /* Setup process working directory. */
  dirname = g_path_get_dirname (argv[1]);
  basename = g_path_get_basename (argv[1]);
  g_assert (dirname != NULL);
  g_assert (basename != NULL);
  g_assert (g_chdir (dirname) == 0);
  g_free (dirname);

  /* Open the NCLua state.  */
  ncluaw_state = ncluaw_open (basename, opt_width, opt_height, &errmsg);
  g_free (basename);
  if (unlikely (ncluaw_state == NULL))
    {
      print_error (errmsg);
      g_free (errmsg);
      ncluaw_close (ncluaw_state);
      exit (EXIT_FAILURE);
    }

  ncluaw_at_panic (ncluaw_state, panic);

  /* Setup GTK+ callbacks.  */
  g_signal_connect (app, "destroy", G_CALLBACK (gtk_main_quit), NULL);

  if (!opt_scale)
    {
      g_signal_connect (app, "configure-event",
                        G_CALLBACK (resize_callback), NULL);
    }

  g_signal_connect (app, "key-press-event",
                    G_CALLBACK (keyboard_callback),
                    deconst (void *, "press"));

  g_signal_connect (app, "key-release-event",
                    G_CALLBACK (keyboard_callback),
                    deconst (void *, "release"));

  gtk_widget_add_events (app, GDK_BUTTON_PRESS_MASK
                         | GDK_BUTTON_RELEASE_MASK
                         | GDK_POINTER_MOTION_MASK);

  g_signal_connect (app, "button-press-event",
                    G_CALLBACK (pointer_click_callback), NULL);

  g_signal_connect (app, "button-release-event",
                    G_CALLBACK (pointer_click_callback), NULL);

  g_signal_connect (app, "motion-notify-event",
                    G_CALLBACK (pointer_motion_callback), NULL);

  g_signal_connect (app, "draw", G_CALLBACK (draw_callback), NULL);

#if GTK_CHECK_VERSION(3,8,0)
  gtk_widget_add_tick_callback (app, (GtkTickCallback) cycle_callback,
                                NULL, NULL);
#else
  g_timeout_add (1000 / 60, (GSourceFunc) cycle_callback, app);
#endif

  /* Send NCL start event.  */
  ncluaw_send_ncl_event (ncluaw_state, "presentation", "start", "", NULL);

  /* Show interpreter window.  */
  gtk_widget_show_all (app);

  /* Setup panic longjmp.  */
  if (setjmp (panic_jmp))
    {
      exit_status = EXIT_FAILURE;
      goto done;
    }

  /* Event loop.  */
  gtk_main ();

 done:
  ncluaw_close (ncluaw_state);
  exit (exit_status);
}

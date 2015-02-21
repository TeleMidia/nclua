/* nclua.c -- A GTK+-3.0 standalone NCLua player.
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
#include <assert.h>
#include <stdlib.h>
#include <setjmp.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <glib.h>
#include <glib/gstdio.h>
#include <gtk/gtk.h>

#include "ncluaw.h"
#include "macros.h"
#include "luax-macros.h"

#define WIDTH  800
#define HEIGHT 600
static ncluaw_t *ncluaw_state;
static GtkWidget *app;
static jmp_buf panic_jmp;

static void
panic (arg_unused (ncluaw_t *nw), const char *message)
{
  luax_dump_stack (cast (lua_State *, ncluaw_debug_get_lua_state (nw)));
  fprintf (stderr, "error: %s\n", message);
  longjmp (panic_jmp, 1);
}

#if GTK_CHECK_VERSION(3,8,0)
static gboolean
cycle_callback (GtkWidget *canvas, arg_unused (gpointer frame_clock),
                arg_unused (gpointer data))
#else
static gboolean
cycle_callback (GtkWidget *canvas)
#endif
{
  ncluaw_event_t *evt;

  ncluaw_cycle (ncluaw_state);

  /* NCL */
  evt = ncluaw_receive (ncluaw_state);
  if (evt != NULL
      && evt->cls == NCLUAW_EVENT_NCL
      && streq (evt->u.ncl.type, "presentation")
      && streq (evt->u.ncl.action, "stop") && streq (evt->u.ncl.name, ""))
    {
      ncluaw_event_free (evt);
      gtk_widget_destroy (app);
      return G_SOURCE_REMOVE;
    }

  gtk_widget_queue_draw (canvas);
  return G_SOURCE_CONTINUE;
}

static gboolean
draw_callback (arg_unused (GtkWidget *canvas), cairo_t *cr,
               arg_unused (gpointer data))
{
  cairo_surface_t *sfc;
  sfc = (cairo_surface_t *) ncluaw_debug_get_surface (ncluaw_state);
  cairo_set_source_surface (cr, sfc, 0, 0);
  cairo_paint (cr);
  return TRUE;
}

static gboolean
keyboard_callback (arg_unused (GtkWidget *widget), GdkEventKey *e,
                   gpointer type)
{
  const char *key;
  int free_key = FALSE;

  switch (e->keyval)
    {
    case GDK_KEY_Escape:
      gtk_widget_destroy (app);
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

static gboolean
pointer_motion_callback (arg_unused (GtkWidget *widget),
                         GdkEventMotion *e, arg_unused (const char *type))
{
  ncluaw_send_pointer_event (ncluaw_state, "move", (int) e->x, (int) e->y);
  return TRUE;
}

static gboolean
pointer_click_callback (arg_unused (GtkWidget *widget), GdkEventButton *e,
                        arg_unused (gpointer data))
{
  const char *type;

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

  ncluaw_send_pointer_event (ncluaw_state, type, (int) e->x, (int) e->y);
  return TRUE;
}

int
main (int argc, char **argv)
{
  GtkWidget *canvas;
  char *errmsg = NULL;
  int status = EXIT_SUCCESS;

  gchar *dirname;
  gchar *basename;

  if (unlikely (argc != 2))
    {
      fprintf (stderr, "usage: nclua [OPTION]... FILE\n");
      exit (EXIT_FAILURE);
    }

  gtk_init (&argc, &argv);

  dirname = g_path_get_dirname (argv[1]);
  basename = g_path_get_basename (argv[1]);
  assert (g_chdir (dirname) == 0);

  ncluaw_state = ncluaw_open (basename, WIDTH, HEIGHT, &errmsg);
  if (unlikely (ncluaw_state == NULL))
    {
      fprintf (stderr, "error: %s\n", errmsg);
      free (errmsg);
      exit (EXIT_FAILURE);
    }

  ncluaw_at_panic (ncluaw_state, panic);

  g_free (dirname);
  g_free (basename);

  app = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  assert (app != NULL);         /* cannot fail */
  gtk_window_set_title (GTK_WINDOW (app), "NCLua");
  gtk_widget_set_size_request (app, WIDTH, HEIGHT);
  gtk_window_set_resizable (GTK_WINDOW (app), FALSE);

  g_signal_connect (app, "destroy", G_CALLBACK (gtk_main_quit), NULL);

  g_signal_connect (app, "key-press-event",
                    G_CALLBACK (keyboard_callback),
                    deconst (void *, "press"));

  g_signal_connect (app, "key-release-event",
                    G_CALLBACK (keyboard_callback),
                    deconst (void *, "release"));

  canvas = gtk_drawing_area_new ();
  assert (canvas != NULL);      /* cannot fail */
  gtk_widget_add_events (canvas, GDK_BUTTON_PRESS_MASK
                         | GDK_BUTTON_RELEASE_MASK
                         | GDK_POINTER_MOTION_MASK);

  g_signal_connect (canvas, "button-press-event",
                    G_CALLBACK (pointer_click_callback), NULL);

  g_signal_connect (canvas, "button-release-event",
                    G_CALLBACK (pointer_click_callback), NULL);

  g_signal_connect (canvas, "motion-notify-event",
                    G_CALLBACK (pointer_motion_callback), NULL);

  g_signal_connect (canvas, "draw", G_CALLBACK (draw_callback), NULL);

  gtk_container_add (GTK_CONTAINER (app), canvas);

#if GTK_CHECK_VERSION(3,8,0)
  gtk_widget_add_tick_callback (canvas, (GtkTickCallback) cycle_callback,
                                NULL, NULL);
#else
  g_timeout_add (1000 / 60, (GSourceFunc) cycle_callback, canvas);
#endif

  /* NCL */
  ncluaw_send_ncl_event (ncluaw_state, "presentation", "start", "", NULL);

  gtk_widget_show_all (app);

  if (setjmp (panic_jmp))
    {
      status = EXIT_FAILURE;
      goto panic;
    }

  gtk_main ();

 panic:
  ncluaw_close (ncluaw_state);
  exit (status);
}

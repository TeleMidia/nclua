/* nclua-gst.c -- A GStreamer standalone NCLua player.
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
#include <stdlib.h>
#include <stdio.h>
#include "aux-gst.h"

/* Globals: */
static GstElement *pipeline;
static GMainLoop *loop;
static int exit_status = EXIT_SUCCESS;

static void
dump_message (const gchar *prefix, GstMessage *msg)
{
  static guint64 serial = 0;
  const GstStructure *st;

  g_print ("#%" G_GUINT64_FORMAT " t:%p %s %s: ",
           serial++, (void *) g_thread_self (), prefix,
           GST_STR_NULL (GST_ELEMENT_NAME (GST_MESSAGE_SRC (msg))));

  st = gst_message_get_structure (msg);
  if (st != NULL)
    {
      gchar *s = gst_structure_to_string (st);
      g_print ("%s\n\n", s);
      g_free (s);
    }
  else
    {
      g_print ("(empty)\n\n");
    }
}

static GstBusSyncReply
bus_sync_callback (unused (GstBus *bus), GstMessage *msg,
                   unused (gpointer data))
{
  dump_message ("SYNC", msg);
  return GST_BUS_PASS;
}

static gboolean
bus_async_callback (unused (GstBus *bus), GstMessage *msg,
                    unused (gpointer data))
{
  dump_message ("ASYNC", msg);
  switch (GST_MESSAGE_TYPE (msg))
    {
    case GST_MESSAGE_ERROR:
      {
        GError *errobj;
        gchar *errmsg;

        gst_message_parse_error (msg, &errobj, &errmsg);
        g_print ("error: %s\n", errmsg);
        g_error_free (errobj);
        g_free (errmsg);
        exit_status = EXIT_FAILURE;
        g_main_loop_quit (loop);
        break;
      }
    case GST_MESSAGE_WARNING:
      {
        GError *errobj;
        gchar *errmsg;

        gst_message_parse_warning (msg, &errobj, &errmsg);
        g_print ("warning: %s\n", errmsg);
        g_error_free (errobj);
        g_free (errmsg);
        break;
      }
    case GST_MESSAGE_EOS:
      {
        g_main_loop_quit (loop);
        break;
      }
    default:
      {
        break;
      }
    }
  fflush (NULL);
  return TRUE;
}

int
main (int argc, char **argv)
{
  GstElement *nclua;
  GstElement *sink;
  GstBus *bus;
  GstStateChangeReturn ret;

  if (unlikely (argc != 2))
    {
      g_print ("usage: nclua FILE\n");
      exit (EXIT_FAILURE);
    }

  gst_init (&argc, &argv);

  loop = g_main_loop_new (NULL, FALSE);
  g_assert (loop != NULL);

  pipeline = gst_pipeline_new (NULL);
  g_assert (pipeline != NULL);

  nclua = gst_element_factory_make ("nclua", NULL);
  g_assert (nclua != NULL);
  g_object_set (G_OBJECT (nclua), "file", argv[1], NULL);

  sink = gst_element_factory_make ("ximagesink", NULL);
  g_assert (sink != NULL);

  g_assert (gst_bin_add (GST_BIN (pipeline), nclua));
  g_assert (gst_bin_add (GST_BIN (pipeline), sink));
  g_assert (gst_element_link (nclua, sink));

  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  g_assert (bus != NULL);

  gst_bus_set_sync_handler (bus, bus_sync_callback, NULL, NULL);
  gst_bus_add_watch (bus, bus_async_callback, NULL);
  gst_object_unref (bus);

  ret = gst_element_set_state (pipeline, GST_STATE_PLAYING);
  if (ret == GST_STATE_CHANGE_ASYNC)
    ret = gst_element_get_state (pipeline, NULL, NULL, GST_CLOCK_TIME_NONE);
  g_assert (ret == GST_STATE_CHANGE_SUCCESS);

  g_main_loop_run (loop);

  gst_element_set_state (pipeline, GST_STATE_NULL);
  gst_object_unref (GST_OBJECT (pipeline));
  g_main_loop_unref (loop);

  exit (exit_status);
}

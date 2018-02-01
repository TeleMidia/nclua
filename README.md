![NCLua](contrib/nclua.png)

The NCLua library adds event handling and 2D graphics to Lua scripts.
Programs written in C can use libnclua to run embedded NCLua scripts, i.e.,
Lua scripts that use the APIs exported by libnclua; Lua scripts can also use
libnclua, either through the C API or by requiring the appropriated modules
-- e.g., `canvas` for 2D graphics, `event` for general event handling,
`event.stopwatch` for stopwatch timers, `event.tcp_socket` for asynchronous
TCP sockets, `event.http_soup` for asynchronous HTTP requests, etc.  The
NCLua library comes with a standalone interpreter, called `nclua`
(cf. [src/nclua.c](src/nclua.c)), which can be used to run NCLua scripts.

For stable releases and binaries, cf.
http://www.telemidia.puc-rio.br/~gflima/nclua.

For the latest sources, cf.
https://github.com/telemidia/nclua.

NCLua is the Lua dialect used by the Brazilian digital TV middleware, called
Ginga (cf. http://www.ginga.org.br).  The reference implementation of
Ginga (>= 0.14) uses libnclua to run NCLua scripts.

Dependencies
------------

Required:
* Lua >= 5.2, http://www.lua.org
* Cairo >= 1.10, http://cairographics.org
* GLib >= 2.32, https://developer.gnome.org/glib
* Pango >= 1.30, http://www.pango.org

Optional:
* GIO >= 2.32, https://developer.gnome.org/gio
* Libsoup >= 2.42, https://developer.gnome.org/libsoup
* GTK+ >= 3.4.2, http://www.gtk.org

GIO is used by the `tcp` event class, Libsoup is used by the `http` event
class, and GTK+ is used by the `nclua` binary.  These libraries are
optional, if they are not present the corresponding modules are not built.

Canvas API
----------

For a complete reference, cf. [nclua/canvas.c](nclua/canvas.c).

Functions:
* `canvas.new`            creates a new canvas
* `canvas:attrAntiAlias`  gets or sets the anti-alias attribute
* `canvas:attrClip`       gets or sets the clip region
* `canvas:attrColor`      gets or sets the color attribute
* `canvas:attrCrop`       gets or sets the crop region
* `canvas:attrFilter`     gets or sets the filter attribute
* `canvas:attrFlip`       gets or sets the flip attribute
* `canvas:attrFont`       gets or sets the font attribute
* `canvas:attrLineWidth`  gets or sets the line width attribute
* `canvas:attrOpacity`    gets or sets the opacity attribute
* `canvas:attrRotation`   gets or sets the rotation attribute
* `canvas:attrScale`      gets or sets the scale attribute
* `canvas:attrSize`       gets the dimensions in pixels
* `canvas:clear`          clears canvas
* `canvas:compose`        composes two canvas
* `canvas:drawEllipse`    draws an ellipse
* `canvas:drawLine`       draws a line
* `canvas:drawPolygon`    draws a polygon
* `canvas:drawRect`       draws a rectangle
* `canvas:drawRoundRect`  draws a rectangle with rounded corners
* `canvas:drawText`       draws text
* `canvas:flush`          commits the pending operations
* `canvas:measureText`    measures text
* `canvas:pixel`          gets or sets pixel

Internal functions (for debugging):
* `canvas:_dump_to_file`    dumps canvas content to PNG file
* `canvas:_dump_to_memory`  dumps canvas content to memory address
* `canvas:_resize`          resizes canvas content
* `canvas:_surface`         returns a pointer to canvas content

Dir API
-------

For a complete reference, cf. [nclua/dir.c](nclua/dir.c).

Functions:
* `dir.dir`  gets an iterator for path
* `dir.test` tests whether path satisfies a given query

Event API
---------

For a complete reference, cf. User API section in
[nclua/event/init.lua](nclua/event/init.lua).

Event classes:
* `ncl`      NCL (Nested Context Language) events
* `key`      keyboard input
* `pointer`  mouse input
* `http`     HTTP requests
* `tcp`      TCP/IP messages
* `user`     user defined

Functions:
* `event.post`            posts event into input or output queues
* `event.register`        registers event handler
* `event.timer`           sets up timer that calls a function when expired
* `event.unregister`      unregisters event handler
* `event.uptime`          returns the up-time since script started

Libnclua API (C code)
---------------------

The libnclua API is used by C programs to run NCLua scripts.

Core functions (cf. [lib/nclua.c](lib/nclua.c)):
* `nclua_open`            opens the library
* `nclua_close`           closes the library
* `nclua_cycle`           processes pending events
* `nclua_receive`         receives an event
* `nclua_send`            sends an event
* `nclua_paint`           paints top-level canvas onto memory
* `nclua_resize`          resizes top-level canvas

Wrapper functions (cf. [lib/ncluaw.c](lib/ncluaw.c), Lua-free interface):
* `ncluaw_event_key_init` initializes key event
* `ncluaw_event_ncl_init` initializes NCL event
* `ncluaw_event_pointer_init` initializes pointer event
* `ncluaw_event_clone`    clones event
* `ncluaw_event_free`     frees event
* `ncluaw_event_equals`   compares events
* `ncluaw_open`           opens the wrapper library
* `ncluaw_close`          closes the wrapper library
* `ncluaw_at_panic`       installs panic function
* `ncluaw_cycle`          processes pending events
* `ncluaw_receive`        receives event
* `ncluaw_send`           sends event
* `ncluaw_send_key_event` sends key event
* `ncluaw_send_ncl_event` sends NCL event
* `ncluaw_send_pointer_event` sends pointer event
* `ncluaw_paint`          paints top-level canvas onto memory
* `ncluaw_resize`         resizes top-level canvas

---
Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

Permission is granted to copy, distribute and/or modify this document under
the terms of the GNU Free Documentation License, Version 1.3 or any later
version published by the Free Software Foundation; with no Invariant
Sections, with no Front-Cover Texts, and with no Back-Cover Texts.  A copy
of the license is included in the "GNU Free Documentation License" file as
part of this distribution.

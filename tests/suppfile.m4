dnl suppfile.m4 -- Generate Valgrind suppressions.
changequote([,])dnl
define([suppress],[dnl
{
    $1: $2
    Memcheck:Leak
    ...
    fun:$1
}])dnl

dnl GObject.
suppress(g_object_do_class_init,            GObject type system)
suppress(g_type_add_interface_static,       GObject type system)
suppress(g_type_register_static,            GObject type system)
suppress(gobject_init_ctor,                 GObject initialization)
suppress(type_iface_vtable_base_init_Wm,    GObject initialization)

dnl GIO.
suppress(do_lookup_by_name,                 GIO GResolver lookup by name)
suppress(g_resolver_class_intern_init,      GIO GResolver internal init)
suppress(g_socket_client_class_intern_init, GIO SocketClient internal init)
suppress(lookup_by_name_async,              GIO GResolver lookup by name)
suppress(_g_io_module_get_default)
suppress(g_io_module_load)
suppress(g_io_module_load_module)

dnl GIO Proxy, LibProxy, GConf -- used by GIO GResolver.
suppress(g_libproxy_resolver_init)
suppress(g_libproxy_resolver_lookup_async)
suppress(g_libproxy_resolver_register)
suppress(g_proxy_drive_register)
suppress(g_proxy_mount_register)
suppress(g_proxy_resolver_gnome_init)
suppress(g_proxy_volume_register)
suppress(g_tls_backend_gnutls_register)
suppress(gconf_client_get_default)
suppress(get_libproxy_proxies)

dnl GTK+3.0
suppress(gdk_pixbuf_class_intern_init)
suppress(gdk_display_manager_class_intern_init)

dnl Pango.
suppress(pango_fc_font_class_intern_init,   Pango-Fontconfig internal init)
suppress(pango_find_map)
suppress(pango_language_get_default)

dnl Fontconfig -- used by pango.
suppress(FcDefaultSubstitute)
suppress(FcFontMatch)

dnl Soup.
suppress(g_cancellable_class_init)
suppress(g_tls_connection_class_init)
suppress(soup_auth_manager_class_init)
suppress(soup_connection_class_init)
suppress(soup_message_class_init)
suppress(soup_session_class_init)
suppress(soup_socket_class_init)

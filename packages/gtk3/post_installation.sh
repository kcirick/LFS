#!/bin/bash

echo ">>> Running gtk-query-immodules-3.0 ..."
gtk-query-immodules-3.0 --update-cache

echo ">>> Running glib-compile-schemas ..."
glib-compile-schemas /usr/share/glib-2.0/schemas


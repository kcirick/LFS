#!/bin/bash

echo "relinking /usr/lib/libgpg-error.so..."
mv -v /usr/lib/libgpg-error.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libgpg-error.so) /usr/lib/libgpg-error.so

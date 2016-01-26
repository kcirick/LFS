#!/bin/bash

echo "relinking /usr/lib/libgcript..."
mv -v /usr/lib/libgcrypt.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libgcrypt.so) /usr/lib/libgcrypt.so

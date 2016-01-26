#!/bin/bash

find /usr/include/js-17.0/ \
     /usr/lib/libmozjs-17.0.a \
     /usr/lib/pkgconfig/mozjs-17.0.pc \
     -type f -exec chmod -v 644 {} \;

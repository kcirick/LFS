#!/bin/bash

echo "Relinking shared libraries..."
for file in pam pam_misc pamc ; do
   mv -v /usr/lib/lib${file}.so.* /lib
   ln -sfv ../../lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
done

echo ">>> Continue to configuring Linux-PAM"
echo ">>> Re-install shadow and systemd!"
echo


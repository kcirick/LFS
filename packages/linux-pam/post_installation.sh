#!/bin/bash

chmod -v 4755 /sbin/unix_chkpwd 

echo "Relinking shared libraries..."
for file in pam pam_misc pamc ; do
      mv -v /usr/lib/lib${file}.so.* /lib &&
      ln -sfv ../../lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
done

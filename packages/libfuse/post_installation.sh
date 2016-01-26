#!/bin/bash

echo "relinking /usr/lib/libfuse.so ..."
mv -v /usr/lib/libfuse.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libfuse.so) /usr/lib/libfuse.so
rm -rfv /tmp/init.d 

echo "creating /etc/fuse.conf ..."
cat > /etc/fuse.conf << "EOF"
# Set the maximum number of FUSE mounts allowed to non-root users.
# The default is 1000.
#
#mount_max = 1000

# Allow non-root users to specify the 'allow_other' or 'allow_root'
# mount options.
#
#user_allow_other
EOF


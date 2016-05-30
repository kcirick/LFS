#!/bin/bash

mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so

chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod -v 4750 /usr/libexec/dbus-daemon-launch-helper

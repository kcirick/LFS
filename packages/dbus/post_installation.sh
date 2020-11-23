#!/bin/bash

echo "Fixing dbus-daemon-launch-helper ..."
chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod -v 4750            /usr/libexec/dbus-daemon-launch-helper
echo

echo ">>> Continue to configuring DBus"
echo


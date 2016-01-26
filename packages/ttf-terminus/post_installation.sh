#!/bin/bash

echo "Updating fonts..."

fc-cache -s > /dev/null
mkfontscale /usr/share/fonts/misc
mkfontdir /usr/share/fonts/misc

mkdir -p /etc/fonts/conf.d
ln -s ../conf.avail/75-yes-terminus.conf /etc/fonts/conf.d/75-yes-terminus.conf

echo "... done!"

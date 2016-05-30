#!/bin/bash

install -v -dm755 /usr/share/fonts
ln -sfvn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF
ln -sfvn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF


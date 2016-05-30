#!/bin/bash

echo "Updating font cache..."
fc-cache -fs > /dev/null 2>&1
mkfontscale /usr/share/fonts/local
mkfontdir /usr/share/fonts/local


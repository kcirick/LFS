#!/bin/bash

echo "Updating fonts..."

fc-cache -s > /dev/null
mkfontscale usr/share/fonts/TTF
mkfontdir usr/share/fonts/TTF

echo "... done!"

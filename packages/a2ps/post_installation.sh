#!/bin/bash

echo ">>> Install international fonts:"
echo "tar -xf i18n-fonts-0.1.tar.bz2"
echo "cp -v i18n-fonts-0.1/fonts/* /usr/share/a2ps/fonts"
echo "cp -v i18n-fonts-0.1/afm/* /usr/share/a2ps/afm"
echo "pushd /usr/share/a2ps/afm"
echo "   ./make_fonts_map.sh"
echo "   mv fonts.map.new fonts.map"
echo "popd"
echo 


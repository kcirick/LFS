#!/bin/bash

ln -sfv ../ghostscript/9.16/doc /usr/share/doc/ghostscript-9.16

echo "Don't forget to install ghostscript fonts:"
echo "   tar -xvf ../<font-tarball> -C /usr/share/ghostscript --no-same-owner"
echo "   fc-cache -v /usr/share/ghostscript/fonts/ "
echo ""

echo "Test ghostscript with:"
echo "   gs -q -dBATCH /usr/share/ghostscript/9.16/examples/tiger.eps"


#!/bin/bash

echo "Don't forget to install the texmf files"
echo "   tar -xf ../../texlive-20150523-texmf.tar.xz -C /opt/texlive/2015 --strip-components=1"
echo "   mktexlsr"
echo "   fmtutil-sys --all"
echo "   mtxrun --generate"
echo ""


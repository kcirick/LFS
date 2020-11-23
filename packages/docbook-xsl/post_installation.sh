#!/bin/bash

VERSION=1.79.2

if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi 

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/$VERSION" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/$VERSION" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/$VERSION" \
           "/usr/share/xml/docbook/xsl-stylesheets-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/$VERSION" \
           "/usr/share/xml/docbook/xsl-stylesheets-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-$VERSION" \
    /etc/xml/catalog

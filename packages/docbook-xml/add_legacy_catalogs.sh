for DTDVER in 4.1.2 4.2 4.3 4.4; do
   xmlcatalog --noout --add "public" \
      "-//OASIS//DTD DocBook XML V$DTDVER//EN" \
      "http://www.oasis-open.org/docbook/xml/$DTDVER/docbookx.dtd" \
      /etc/xml/docbook
   xmlcatalog --noout --add "rewriteSystem" \
      "http://www.oasis-open.org/docbook/xml/$DTDVER" \
      "file:///usr/share/xml/docbook/xml-dtd-4.5" \
      /etc/xml/docbook
   xmlcatalog --noout --add "rewriteURI" \
      "http://www.oasis-open.org/docbook/xml/$DTDVER" \
      "file:///usr/share/xml/docbook/xml-dtd-4.5" \
      /etc/xml/docbook
   xmlcatalog --noout --add "delegateSystem" \
      "http://www.oasis-open.org/docbook/xml/$DTDVER/" \
      "file:///etc/xml/docbook" \
      /etc/xml/docbook
   xmlcatalog --noout --add "delegateURI" \
      "http://www.oasis-open.org/docbook/xml/$DTDVER/" \
      "file:///etc/xml/docbook" \
      /etc/xml/docbook
done

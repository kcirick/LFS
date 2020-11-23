for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
   xmlcatalog --noout --add "public" \
      "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
      "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
      /etc/xml/docbook

   xmlcatalog --noout --add "rewriteSystem" \
      "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
      "file:///usr/share/xml/docbook/xml-dtd-4.5" \
      /etc/xml/docbook
   xmlcatalog --noout --add "rewriteURI" \
      "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
      "file:///usr/share/xml/docbook/xml-dtd-4.5" \
      /etc/xml/docbook

   xmlcatalog --noout --add "delegateSystem" \
      "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
      "file:///etc/xml/docbook" \
      /etc/xml/catalog
   xmlcatalog --noout --add "delegateURI" \
      "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
      "file:///etc/xml/docbook" \
      /etc/xml/catalog
done

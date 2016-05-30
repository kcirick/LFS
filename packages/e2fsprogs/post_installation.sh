#!/bin/bash

echo ">>> Setting correct permissions"
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

echo
echo ">>> Deal with the info files"
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info


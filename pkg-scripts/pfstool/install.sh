#!/bin/sh

TARGET=pfstool
VERSION=1.4

CWD=$(pwd)
BLD_DIR=/var/pfs/build
PKG_DIR=/var/pfs/packages
LOG_DIR=/var/pfs/log

mkdir -pv $BLD_DIR $PKG_DIR $LOG_DIR

echo "Installing pfstool version $VERSION to /usr/sbin ..."
install -v -m 755 $CWD/pfstool /usr/sbin


if [ ! -f $LOG_DIR/pfs_packages.db ]; then
   echo "Placing pfs_packages.db to $LOG_DIR ..."
   cp -v $CWD/pfs_packages.db $LOG_DIR
fi

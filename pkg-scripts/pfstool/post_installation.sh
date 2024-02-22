#!/bin/bash

if [ ! -s /var/log/packages/pfs_packages.db ]; then
   echo "/var/log/packages/pfs_packages.db cannot be found!"
   echo " --> Place new pfs_packages.db to /var/log/packages"
fi

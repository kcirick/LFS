#!/bin/bash

echo "updating desktop database ..."
install -vdm755 /usr/share/applications
update-desktop-database /usr/share/applications


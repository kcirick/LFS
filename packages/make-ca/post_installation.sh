#!/bin/bash

install -vdm755 /etc/ssl/local

echo "Downloading certificate source..."
/usr/sbin/make-ca -g

echo "Starting update timer..."
systemctl enable update-pki.timer


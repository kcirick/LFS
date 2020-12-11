#!/bin/bash

echo "Downloading certificate source..."
/usr/sbin/make-ca -g

echo "Starting update timer..."
systemctl enable update-pki.timer


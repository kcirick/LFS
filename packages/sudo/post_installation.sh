#!/bin/bash

echo ">>> Creating /etc/pam.d/sudo"
cat > /etc/pam.d/sudo << "EOF"
# Begin /etc/pam.d/sudo

auth      include     system-auth
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so
session   include     system-session

# End /etc/pam.d/sudo
EOF
chmod 644 /etc/pam.d/sudo

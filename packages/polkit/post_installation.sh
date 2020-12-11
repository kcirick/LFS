#!/bin/bash

echo "Creating /etc/pam.d/polkit-1 ..."

cat > /etc/pam.d/polkit-1 << "EOF"
# Begin /etc/pam.d/polkit-1

auth     include     system-auth
account  include     system-account
password include     system-password
session  include     system-session

# End /etc/pam.d/polkit-1
EOF


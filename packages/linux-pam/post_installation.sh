#!/bin/bash

install -vdm755 /etc/pam.d

echo "Creating /etc/pam.d/system-account ..."
cat > /etc/pam.d/system-account << "EOF"
# Begin /etc/pam.d/system-account

account  required    pam_unix.so

# End /etc/pam.d/system-account
EOF

echo "Creating /etc/pam.d/system-auth ..."
cat > /etc/pam.d/system-auth << "EOF"
# Begin /etc/pam.d/system-auth

auth     required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

echo "Creating /etc/pam.d/system-session ..."
cat > /etc/pam.d/system-session << "EOF"
# Begin /etc/pam.d/system-session

session  required    pam_unix.so

# End /etc/pam.d/system-session
EOF

echo "Creating /etc/pam.d/system-password ..."
cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use sha512 hash for encryption use shadow, and try to use any previously
# defined authentication token (chosen password) set by any prior module
password required    pam_unix.so    sha512 shadow try_first_pass

# End /etc/pam.d/system-password
EOF

echo "Creating /etc/pam.d/other ..."
cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth     required    pam_warn.so
auth     required    pam_deny.so
account  required    pam_warn.so
account  required    pam_deny.so
password required    pam_warn.so
password required    pam_deny.so
session  required    pam_warn.so
session  required    pam_deny.so

# End /etc/pam.d/other
EOF


echo ">>> Re-install shadow and systemd!"
echo


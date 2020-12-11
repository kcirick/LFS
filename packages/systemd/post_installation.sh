#!/bin/bash

echo "Modifying /etc/pam.d/system-session ..."
cat >> /etc/pam.d/system-session << "EOF"
# Begin systemd addition

session     required    pam_loginuid.so
session     optional    pam_systemd.so

# End systemd addition
EOF

echo "Creating /etc/pam.d/systemd-user ..."
cat > /etc/pam.d/systemd-user << "EOF"
# Begin /etc/pam.d/systemd-user

account     required    pam_access.so
account     include     system-account

session     required    pam_env.so
session     required    pam_limits.so
session     required    pam_unix.so
session     required    pam_loginuid.so
session     optional    pam_keyinit.so force revoke
session     optional    pam_systemd.so

auth        required    pam_deny.so
password    required    pam-deny.so

# End /etc/pam.d/systemd-user
EOF


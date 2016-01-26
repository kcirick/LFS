#!/bin/bash


ln -sfnv ../cups/doc-2.1.0 /usr/share/doc/cups-2.1.0

echo "ServerName /var/run/cups/cups.sock" > /etc/cups/client.conf

if [ -d /etc/pam.d ]; then
   cat > /etc/pam.d/cups << "EOF"
# Begin /etc/pam.d/cups

auth    include system-auth
account include system-account
session include system-session

# End /etc/pam.d/cups
EOF
fi

echo "***********"
echo "Follow configuration steps at:"
echo "  http://www.linuxfromscratch.org/blfs/view/systemd/pst/cups.html"
echo "***********"

#!/bin/bash

sed -i 's/yes/no/' /etc/default/useradd

echo "Modifying /etc/login.defs ..."
install -v -m644 /etc/login.defs /etc/login.defs.orig
for FUNCTION in FAIL_DELAY \
                FAILLOG_ENAB \
                LASTLOG_ENAB \
                MAIL_CHECK_ENAB \
                OBSCURE_CHECKS_ENAB \
                PORTTIME_CHECKS_ENAB \
                QUOTAS_ENAB \
                CONSOLE MOTD_FILE \
                FTMP_FILE NOLOGINS_FILE \
                ENV_HZ PASS_MIN_LEN \
                SU_WHEEL_ONLY \
                CRACKLIB_DICTPATH \
                PASS_CHANGE_TRIES \
                PASS_ALWAYS_WARN \
                CHFN_AUTH ENCRYPT_METHOD \
                ENVIRON_FILE
do
   sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
done

echo "Creating /etc/pam.d/login ..."
cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth        optional    pam_faildelay.so     delay=3000000

# Check to make sure that the user is allowed to login
auth        requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function.
#auth       required    pam_securetty.so

# Additional group memberships - deisabled by default
#auth       optional    pm_group.so

# include system auth settings
auth        include     system-auth

# Check access for the user
account     required    pam_access.so

# include system account settings
account     include     system-account

# Set default environment variables for the user
session     required    pam_env.so

# Set resource limits for the user
session     required    pam_limits.so

# Display date of last login - disabled by default
#session    optional    pam_lastlog.so

# Disply the message of the day - disabled by default
#session    optional    pam_motd.so

# Check user's mail - disabled by default 
#session    optional    pam_mail.so    standard quiet

# include system session and password settings
session     include     system-session
password    include     system-password

# End /etc/pam.d/login
EOF

echo "Creating /etc/pam.d/passwd ..."
cat > /etc/pam.d/passwd << "EOF"
# Begin /etc/pam.d/passwd

password    include     system-password

# End /etc/pam.d/passwd
EOF

echo "Creating /etc/pam.d/su ..."
cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

# Always allow root
auth     sufficient     pam_rootok.so

# Allow users in the whell group to execute su without a password - disabled by default
#auth    sufficient     pam_wheel.so   trust use_uid

# include system auth settings
auth     include        system-auth

# limit su to users in the wheel group
auth     required       pam_wheel.so   use_uid

# include system account settings
account  include        system-account

# set default environment variables for the service user
session  required       pam_env.so

# include system session settings
session  include        system-session

# End /etc/pam.d/su
EOF

echo "Creating pam.d files for other programs ..."
cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

# Always allow root
auth     sufficient     pam_rootok.so

# include system auth, account, and session settings
auth     include        system-auth
account  include        system-account
session  include        system-session

# Always permit for authentication updates
password required       pam_permit.so

# End /etc/pam.d/chage
EOF

for PROGRAM in chfn chgpasswd chpasswd chsh groupadd groupdel \
               groupmems groupmod newusers useradd userdel usermod
do
   install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
   sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
done

[ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}
[ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}



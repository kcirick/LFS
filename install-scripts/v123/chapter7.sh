#!/bin/bash

if [[ "$(whoami)" != "root" ]] ; then
   echo "Not running as root! Exiting..."
   return;
fi

if ! [[ -d /tools ]]; then
   echo "/tools not found. Maybe not under chroot?"
   return;
fi


cd $LFS/sources

if [[ $1 -eq 1 ]]; then
   echo "nothing to do"
fi #########

#-----
echo "# 7.7. Gettext"
tar -xf gettext-0.22.4.tar.xz
cd gettext-0.22.4

./configure --disable-shared

make || exit 1
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gettext-0.22.4

#-----
echo "# 7.8. Bison"
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bison-3.8.2

#-----
echo "# 7.9. Perl"
tar -xf perl-5.38.2.tar.xz
cd perl-5.38.2

sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Duseshrplib                                 \
		       -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
		       -Darchlib=/usr/lib/perl5/5.38/core_perl      \
		       -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
		       -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
		       -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
		       -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf perl-5.38.2

#-----
echo "# 7.10. Python"
tar -xf Python-3.12.2.tar.xz
cd Python-3.12.2

./configure --prefix=/usr        \
	         --enable-shared      \
	         --without-ensurepip

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf Python-3.12.2

#-----
echo "# 7.11. Texinfo"
tar -xf texinfo-7.1.tar.xz
cd texinfo-7.1

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf texinfo-7.1

#-----
echo "# 7.12. util-linux"
tar -xf util-linux-2.39.3.tar.xz
cd util-linux-2.39.3

mkdir -pv /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --libdir=/usr/lib                         \
            --runstatedir=/run                        \
            --docdir=/usr/share/doc/util-linux-2.39.3 \
            --disable-chfn-chsh                       \
            --disable-login                           \
            --disable-nologin                         \
            --disable-su                              \
            --disable-setpriv                         \
            --disable-runuser                         \
            --disable-pylibmount                      \
            --disable-static                          \
            --without-python

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf util-linux-2.39.3


echo "Continue to 7.14: Cleaning up and saving the temporary system"
echo 

echo ""
echo "=== End of Chapter 7 ==="
echo ""

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
tar -xf gettext-0.24.tar.xz
cd gettext-0.24

./configure --disable-shared

make || exit 1

cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gettext-0.24

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
tar -xf perl-5.40.1.tar.xz
cd perl-5.40.1

sh Configure -des                                         \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D useshrplib                                 \
	     -D privlib=/usr/lib/perl5/5.40/core_perl      \
	     -D archlib=/usr/lib/perl5/5.40/core_perl      \
	     -D sitelib=/usr/lib/perl5/5.40/site_perl      \
	     -D sitearch=/usr/lib/perl5/5.40/site_perl     \
	     -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
	     -D vendorarch=/usr/lib/perl5/5.40/vendor_perl

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf perl-5.40.1

#-----
echo "# 7.10. Python"
tar -xf Python-3.13.2.tar.xz
cd Python-3.13.2

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
rm -rf Python-3.13.2

#-----
echo "# 7.11. Texinfo"
tar -xf texinfo-7.2.tar.xz
cd texinfo-7.2

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf texinfo-7.2

#-----
echo "# 7.12. util-linux"
tar -xf util-linux-2.40.4.tar.xz
cd util-linux-2.40.4

mkdir -pv /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --libdir=/usr/lib                         \
            --runstatedir=/run                        \
            --docdir=/usr/share/doc/util-linux-2.40.4 \
            --disable-chfn-chsh                       \
            --disable-login                           \
            --disable-nologin                         \
            --disable-su                              \
            --disable-setpriv                         \
            --disable-runuser                         \
            --disable-pylibmount                      \
            --disable-static                          \
	    --disable-liblastlog2		      \
            --without-python

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf util-linux-2.40.4


echo "Continue to 7.14: Cleaning up and saving the temporary system"
echo

echo ""
echo "=== End of Chapter 7 ==="
echo ""

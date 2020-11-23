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

#-----
echo "# 7.7. Libstdc++ from gcc-10.2.0 Pass 2"
rm -rf gcc-10.2.0
tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0

ln -s gthr-posix.h libgcc/gthr-default.h

mkdir -pv build && cd build
../libstdc++-v3/configure --prefix=/usr                   \
                          CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
                          --disable-multilib              \
                          --disable-nls                   \
                          --disable-libstdcxx-pch         \
			  --host=$(uname -m)-lfs-linux-gnu

make || exit 1
make install || exit 1

cd $LFS/sources
#rm -rf gcc-9.2.0

#-----
echo "# 7.8. Gettext-0.21"
tar -xf gettext-0.21.tar.xz
cd gettext-0.21

./configure --disable-shared

make || exit 1
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd $LFS/sources
rm -rf gettext-0.21

#-----
echo "# 7.9. Bison-3.7.1"
tar -xf bison-3.7.1.tar.xz
cd bison-3.7.1

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf bison-3.7.1

#-----
echo "# 7.10. Perl-5.32.0"
tar -xf perl-5.32.0.tar.xz
cd perl-5.32.0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
		  -Dprivlib=/usr/lib/perl5/5.32/core_perl \
		  -Darchlib=/usr/lib/perl5/5.32/core_perl \
		  -Dsitelib=/usr/lib/perl5/5.32/site_perl \
		  -Dsitearch=/usr/lib/perl5/5.32/site_perl \
		  -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
		  -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf perl-5.32.0

#-----
echo "# 7.11. Python-3.8.5"
tar -xf Python-3.8.5.tar.xz
cd Python-3.8.5

./configure --prefix=/usr \
	    --enable-shared \
	    --without-ensurepip

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf Python-3.8.5

#-----
echo "# 7.12. Texinfo-6.7"
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf texinfo-6.7

#-----
echo "# 7.13. util-linux-2.36"
tar -xf util-linux-2.36.tar.xz
cd util-linux-2.36

mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.36 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf util-linux-2.36


echo "Continue to 7.14: Cleaning up and saving the temporary system"
echo 

echo ""
echo "=== End of Chapter 7 ==="
echo ""


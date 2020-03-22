#!/bin/bash

if [[ "$(whoami)" != "root" ]] ; then
   echo "Not running as root! Exiting..."
   return;
fi

if ! [[ -d /tools ]]; then
   echo "/tools not found. Maybe not under chroot?"
   return;
fi

section=$1

cd $LFS/sources

if [ $section -eq 1 ]; then

echo "# 6.7. Linux API Headers"
tar -xf linux-5.5.3.tar.xz
cd linux-5.5.3
make mrproper || exit 1
make headers || exit 1
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include/* /usr/include
cd $LFS/sources
rm -rf linux-5.5.3

#-----
echo "# 6.8. Man-pages-5.05"
tar -xf man-pages-5.05.tar.xz
cd man-pages-5.05
make install || exit 1
cd $LFS/sources
rm -rf man-pages-5.05

#-----
echo "# 6.9. Glibc-2.31"
tar -xf glibc-2.31.tar.xz
cd glibc-2.31
patch -Np1 -i ../glibc-2.31-fhs-1.patch
ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
mkdir -v build && cd build
CC="gcc -ffile-prefix-map=/tools=/usr" \
../configure    \
   --prefix=/usr          \
   --disable-werror       \
   --enable-kernel=3.2    \
   --enable-stack-protector=strong \
   --with-headers=/usr/include     \
   libc_cv_slibdir=/lib
make || exit 1
ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install || exit 1

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service

mkdir -pv /usr/lib/locale
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i en_CA -f ISO-8859-1 en_CA
localedef -i en_CA -f UTF-8 en_CA.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8

# 6.9.2.1
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# 6.9.2.2
tar -xf ../../tzdata2019c.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
      asia australasia backward pacificnew systemv; do
   zic -L /dev/null   -d $ZONEINFO       ${tz}
   zic -L /dev/null   -d $ZONEINFO/posix ${tz}
   zic -L leapseconds -d $ZONEINFO/right ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/Canada/Eastern /etc/localtime

# 6.9.2.3
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

cd $LFS/sources
rm -rf glibc-2.31

#-----
echo "# 6.10. Adjusting the Toolchain"
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
   -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
   -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
      `dirname $(gcc --print-libgcc-file-name)`/specs

cc dummy.c -v -Wl,--verbose &> log-6.10_long.out
readelf -l a.out | grep ': /lib' > log-6.10.out
rm -v a.out

echo "Check log-6.10.out and log-6.10_long.out"
echo
read -p "Press Y to contiue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi

elif [ $section -eq 2 ]; then

#-----
echo "# 6.11. Zlib-1.2.11"
tar -xf zlib-1.2.11.tar.xz
cd zlib-1.2.11
./configure --prefix=/usr
make || exit 1
make install || exit 1
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd $LFS/sources
rm -rf zlib-1.2.11

#-----
echo "# 6.12. Bzip2-1.0.8"
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so || exit 1
make clean
make || exit 1
make PREFIX=/usr install || exit 1
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd $LFS/sources
rm -rf bzip2-1.0.8

#-----
echo "# 6.13. Xz-5.2.4"
tar -xf xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4
make || exit 1
make install || exit 1
mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd $LFS/sources
rm -rf xz-5.2.4

#-----
echo "# 6.14. File-5.38"
tar -xf file-5.38.tar.gz
cd file-5.38
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf file-5.38

#-----
echo "# 6.15. Readline-8.0"
tar -xf readline-8.0.tar.gz
cd readline-8.0
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-8.0
make SHLIB_LIBS="-L/tools/lib -lncurses" || exit 1
make SHLIB_LIBS="-L/tools/lib -lncurses" install || exit 1
mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
cd $LFS/sources
rm -rf readline-8.0

#-----
echo "# 6.16. M4-1.4.18"
tar -xf m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf m4-1.4.18

#-----
echo "# 6.17 BC-2.5.3"
tar -xf bc-2.5.3.tar.gz
cd bc-2.5.3
PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -03
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf bc-2.5.3

#-----
echo "# 6.18. Binutils-2.34"
tar -xf binutils-2.34.tar.xz
cd binutils-2.34
sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
mkdir -v build && cd build
../configure --prefix=/usr       \
	     --enable-gold       \
	     --enable-ld=default \
	     --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
	     --enable-64-bit-bfd \
	     --with-system-zlib
make tooldir=/usr || exit 1
make tooldir=/usr install || exit 1
cd $LFS/sources
rm -rf binutils-2.34

#-----
echo "# 6.19. GMP-6.2.0"
tar -xf gmp-6.2.0.tar.xz
cd gmp-6.2.0
./configure --prefix=/usr \
            --enable-cxx  \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.0
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gmp-6.2.0

#-----
echo "# 6.20. MPFR-4.0.2"
tar -xf mpfr-4.0.2.tar.xz
cd mpfr-4.0.2
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.2
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf mpfr-4.0.2

#-----
echo "# 6.21. MPC-1.1.0"
tar -xf mpc-1.1.0.tar.gz
cd mpc-1.1.0
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf mpc-1.1.0

#-----
echo "6.22. Attr-2.4.48"
tar -xf attr-2.4.48.src.tar.gz
cd attr-2.4.48
./configure --prefix=/usr \
	    --disable-static \
	    --sysconfdir=/etc \
	    --docdir=/usr/share/doc/attr-2.4.48
make || exit 1
make install || exit 1
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd $LFS/sources
rm -rf attr-2.4.48

#-----
echo "6.23. Acl-2.2.53"
tar -xf acl-2.2.53.src.tar.gz
cd acl-2.2.53
./configure --prefix=/usr \
            --disable-static \
            --libexecdir=/usr/lib \
	    --docdir=/usr/share/doc/acl-2.2.53
make || exit 1
make install || exit 1
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd $LFS/sources
rm -rf acl-2.2.53

#-----
echo "# 6.24. Shadow-4.8.1"
tar -xf shadow-4.8.1.tar.xz
cd shadow-4.8.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32
make || exit 1
make install || exit 1

# 6.24.2 configuring shadow
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here
cd $LFS/sources
rm -rf shadow-4.8.1

#-----
echo "# 6.25. GCC-9.2.0"
tar -xf gcc-9.2.0.tar.xz
cd gcc-9.2.0
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
sed -e '1161 s|^|//|' -i libsanitizer/sanitizer_platform_limits_posix.cc
mkdir -v build && cd build
SED=sed                     \
../configure                \
   --prefix=/usr            \
   --enable-languages=c,c++ \
   --disable-multilib       \
   --disable-bootstrap      \
   --with-system-zlib
make || exit 1
make install || exit 1
rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/9.2.0/include-fixed/bits/
chown -v -R root:root /usr/lib/gcc/*linux-gnu/9.2.0/include{,-fixed}
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/9.2.0/liblto_plugin.so /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd $LFS/sources

cc dummy.c -v -Wl,--verbose &> log-6.17_long.out
readelf -l a.out | grep ': /lib' > log-6.17.out
rm -v a.out

echo "Check log-6.17.out and log-6.17_long.out"
echo
read -p "Press Y to contiue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi

rm -rf gcc-9.2.0

elif [ $section -eq 3 ]; then

#-----
echo "# 6.26. Pkg-config-0.29.2"
tar -zxf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr         \
            --with-internal-glib  \
            --disable-host-tool   \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf pkg-config-0.29.2

#-----
echo "# 6.27. Ncurses-6.2"
tar -xf ncurses-6.2.tar.gz
cd ncurses-6.2
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec
make || exit 1
make install || exit 1
mv -v /usr/lib/libncursesw.so.6* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
   rm -vf                    /usr/lib/lib${lib}.so
   echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
   ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so

cd $LFS/sources
rm -rf ncurses-6.2

#-----
echo "6.28. Libcap-2.31"
tar -xf libcap-2.31.tar.xz
cd libcap-2.31
sed -i '/install.*STA...LIBNAME/d' libcap/Makefile
make lib=lib || exit 1
make lib=lib install || exit 1
chmod -v 755 /lib/libcap.so.2.31
cd $LFS/sources
rm -rf libcap-2.31

#-----
echo "# 6.29. Sed-4.8"
tar -xf sed-4.8.tar.xz
cd sed-4.8
sed -i 's/usr/tools/' build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in
./configure --prefix=/usr --bindir=/bin 
make || exit 
make install || exit 1
cd $LFS/sources
rm -rf sed-4.8

#-----
echo "# 6.30. Psmisc-23.2"
tar -xf psmisc-23.2.tar.xz
cd psmisc-23.2
./configure --prefix=/usr
make || exit 1
make install || exit 1
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd $LFS/sources
rm -rf psmisc-23.2

#-----
echo "# 6.31. Iana-etc-2.30"
tar -xf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf iana-etc-2.30

#-----
echo "# 6.32. Bison-3.5.2"
tar -xf bison-3.5.2.tar.xz
cd bison-3.5.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.5.2
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf bison-3.5.2

#-----
echo "# 6.33. Flex-2.6.4"
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4
sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make || exit 1
make install || exit 1
ln -sv flex /usr/bin/lex
cd $LFS/sources
rm -rf flex-2.6.4

#-----
echo "# 6.34. Grep-3.4"
tar -xf grep-3.4.tar.xz
cd grep-3.4
./configure --prefix=/usr --bindir=/bin
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf grep-3.4

#-----
echo "# 6.35. Bash-5.0"
tar -xf bash-5.0.tar.gz
cd bash-5.0
patch -Np1 -i ../bash-5.0-upstream_fixes-1.patch
./configure --prefix=/usr                    \
            --docdir=/usr/share/doc/bash-5.0 \
            --without-bash-malloc            \
            --with-installed-readline
make || exit 1
make install || exit 1
mv -vf /usr/bin/bash /bin
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd $LFS/sources
rm -rf bash-5.0

#-----
echo "# 6.36. Libtool-2.4.6"
tar -xf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf libtool-2.4.6

#-----
echo "# 6.37. GDBM-1.18.1"
tar -xf gdbm-1.18.1.tar.gz
cd gdbm-1.18.1
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gdbm-1.18.1

#-----
echo "6.38. Gperf-3.1"
tar -xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gperf-3.1

#-----
echo "6.39. Expat-2.2.9"
tar -xf expat-2.2.9.tar.xz
cd expat-2.2.9
sed -i 's|usr/bin/env |bin/|' run.sh.in
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat-2.2.9
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf expat-2.2.9

#-----
echo "# 6.40. Inetutils-1.9.4"
tar -xf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make || exit 1
make install || exit 1
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd $LFS/sources
rm -rf inetutils-1.9.4

#-----
echo "# 6.41. Perl-5.30.1"
tar -xf perl-5.30.1.tar.xz
cd perl-5.30.1
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib			\
		  -Dusethreads
make || exit 1
make install || exit 1
unset BUILD_ZLIB BUILD_BZIP2
cd $LFS/sources
rm -rf perl-5.30.1

#-----
echo "6.42. XML::Parser-2.46"
tar -xf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46
perl Makefile.PL
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf XML-Parser-2.46

#-----
echo "6.43. Intltool-0.51.0"
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf intltool-0.51.0

#-----
echo "# 6.44. Autoconf-2.69"
tar -xf autoconf-2.69.tar.xz
cd autoconf-2.69
sed '361 s/{/\\{/' -i bin/autoscan.in
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf autoconf-2.69

#-----
echo "# 6.45. Automake-1.16.1"
tar -xf automake-1.16.1.tar.xz
cd automake-1.16.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf automake-1.16.1

#-----
echo "# 6.46. Kmod-26"
tar -xf kmod-26.tar.xz
cd kmod-26
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make || exit 1
make install || exit 1
for target in depmod insmod lsmod modinfo modprobe rmmod; do
   ln -sv ../bin/kmod /sbin/$target
done
ln -sfv kmod /bin/lsmod
cd $LFS/sources
rm -rf kmod-26

#-----
echo "# 6.47. Gettext-0.20.1"
tar -xf gettext-0.20.1.tar.xz
cd gettext-0.20.1
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.20.1
make || exit 1
make install || exit 1
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd $LFS/sources
rm -rf gettext-0.20.1

#-----
echo "# 6.48 Libelf from Elfutils-0.178"
tar -xf elfutils-0.178.tar.bz2
cd elfutils-0.178
.configure --prefix=/usr --disable-debuginfod
make || exit 1
make -C libelf install || exit 1
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd $LFS/sources
rm -rf elfutils-0.178

#----
echo "# 6.49 Libffi-3.3"
tar -xf libffi-3.3.tar.gz
cd libffi-3.3
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf libffi-3.3

#-----
echo "# 6.50 OpenSSL-1.1.1d"
tar -xf openssl-1.1.1d.tar.gz
cd openssl-1.1.1d
./config --prefix=/usr \
	 --openssldir=/etc/ssl \
	 --libdir=lib \
	 shared \
	 zlib-dynamic
make || exit 1
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install || exit 1
cd $LFS/sources
rm -rf openssl-1.1.1d

#-----
echo "# 6.51 Python-3.8.1"
tar -xf Python-3.8.1.tar.xz
cd Python-3.8.1
./configure --prefix=/usr \
	    --enable-shared \
	    --with-system-expat \
	    --with-system-ffi \
	    --with-ensurepip=yes
make || exit 1
make install || exit 1
chmod -v 755 /usr/lib/libpython3.8.so
chmod -v 755 /usr/lib/libpython3.so
ln -sfv pip3.8 /usr/bin/pip3
cd $LFS/sources
rm -rf Python-3.8.1

#-----
echo "# 6.52 Ninja-1.10.0"
tar -xf ninja-1.10.0.tar.gz
cd ninja-1.10.0
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDM644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
cd $LFS/sources
rm -rf ninja-1.10.0

#-----
echo "# 6.53 Meson-0.53.1"
tar -xf meson-0.53.1.tar.gz
cd meson-0.53.1
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
cd $LFS/sources
rm -rf meson-0.53.1

#-----
echo "# 6.54. Coreutils-8.31"
tar -xf coreutils-8.31.tar.xz
cd coreutils-8.31
patch -Np1 -i ../coreutils-8.31-i18n-1.patch 
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make || exit 1
make install || exit 1
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice,touch} /bin
#mv -v /usr/bin/[ /bin
cd $LFS/sources
rm -rf coreutils-8.31

#-----
echo "# 6.55 Check 0.14.0"
tar -xf check-0.14.0.tar.gz
cd check-0.14.0
./configure --prefix=/usr
make || exit 1
make docdir=/usr/share/doc/check-0.14.0 install &&
	sed -i '1 s/tools/usr/' /usr/bin/checkmk
cd $LFS/sources
rm -rf check-0.14.0

#-----
echo "# 6.56. Diffutils-3.7"
tar -xf diffutils-3.7.tar.xz
cd diffutils-3.7
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf diffutils-3.7

#-----
echo "# 6.57. Gawk-5.0.1"
tar -xf gawk-5.0.1.tar.xz
cd gawk-5.0.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gawk-5.0.1

#-----
echo "# 6.58. Findutils-4.7.0"
tar -xf findutils-4.7.0.tar.xz
cd findutils-4.7.0
./configure --prefix=/usr --localstatedir=/var/lib/locate
make || exit 1
make install || exit 1
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
cd $LFS/sources
rm -rf findutils-4.7.0

#-----
echo "# 6.59. Groff-1.22.4"
tar -xf groff-1.22.4.tar.gz
cd groff-1.22.4
PAGE=letter ./configure --prefix=/usr
make -j1 || exit 1
make install || exit 1
cd $LFS/sources
rm -rf groff-1.22.4

#-----
echo "# 6.60. GRUB-2.04"
tar -xf grub-2.04.tar.xz
cd grub-2.04
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make || exit 1
make install || exit 1
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
cd $LFS/sources
rm -rf grub-2.04

#-----
echo "# 6.61. Less-551"
tar -xf less-551.tar.gz
cd less-551
./configure --prefix=/usr --sysconfdir=/etc
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf less-551

#-----
echo "# 6.62. Gzip-1.10"
tar -xf gzip-1.10.tar.xz
cd gzip-1.10
./configure --prefix=/usr 
make || exit 1
make install || exit 1
mv -v /usr/bin/gzip /bin
cd $LFS/sources
rm -rf gzip-1.10

#-----
echo "# 6.63 Zstd-1.4.4"
tar -xf zstd-1.4.4.tar.gz
cd zstd-1.4.4
make || exit 1
make prefix=/usr install || exit 1
rm -v /usr/lib/libzstd.a
mv -v /usr/lib/libzstd.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so
cd $LFS/sources
rm -rf zstd-1.4.4

#-----
echo "# 6.64 IPRoute2-5.5.0"
tar -xf iproute2-5.5.0.tar.xz
cd iproute2-5.5.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
sed -i 's/.m_ipt.o//' tc/Makefile
make || exit 1
make DOCDIR=/usr/share/doc/iproute2-5.5.0 install || exit 1
cd $LFS/sources
rm -rf iproute2-5.5.0

#-----
echo "# 6.65. Kbd-2.2.0"
tar -xf kbd-2.2.0.tar.xz
cd kbd-2.2.0
patch -Np1 -i ../kbd-2.2.0-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
./configure --prefix=/usr --disable-vlock
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf kbd-2.2.0

#-----
echo "# 6.66. Libpipeline-1.5.2"
tar -xf libpipeline-1.5.2.tar.gz
cd libpipeline-1.5.2
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf libpipeline-1.5.2

#-----
echo "# 6.67. Make-4.3"
tar -xf make-4.3.tar.gz
cd make-4.3
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf make-4.3

#-----
echo "# 6.68. Patch-2.7.6"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf patch-2.7.6

#-----
echo "# 6.69. Man-DB-2.9.0"
tar -xf man-db-2.9.0.tar.xz
cd man-db-2.9.0
sed -i '/find/s@/usr@@' init/systemd/man-db.service.in
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.9.0 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
	    --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf man-db-2.9.0

#-----
echo "# 6.70. Tar-1.32"
tar -xf tar-1.32.tar.xz
cd tar-1.32
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf tar-1.32

#-----
echo "# 6.71. Texinfo-6.7"
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7
./configure --prefix=/usr --disable-static
make || exit 1
make install || exit 1
make TEXMF=/usr/share/texmf install-tex || exit 1
cd $LFS/sources
rm -rf texinfo-6.7

#-----
echo "# 6.72. Vim-8.2.0190"
tar -xf vim-8.2.0190.tar.gz
cd vim82
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make || exit 1
make install || exit 1
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
   ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim74/doc /usr/share/doc/vim-8.2.0190
# 6.72.2 configuring vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2

set nu
set ruler

set tabstop=3
set shiftwidth=3
set expandtab

syntax on

if (&term == "xterm") || (&term == "putty")
   set background=dark
endif

" End /etc/vimrc
EOF
cd $LFS/sources
rm -rf vim82

#-----
echo "# 6.73 Systemd-244"
tar -xf systemd-244.tar.gz
cd systemd-244
ln -sf /tools/bin/true /usr/bin/xsltproc
for file in /tools/lib/lib{blkid,mount,uuid}.so*; do
	ln -sf $file /usr/lib/
done
tar -xf ../systemd-man-pages-244.tar.xz
sed '177,$ d' -i src/resolve/meson.build
sed -i 's/GROUP="render", //' rules.d/50-udev-default.rules.in
mkdir -p build ; cd build
PKG_CONFIG_PATH="/usr/lib/pkgconfig:/tools/lib/pkgconfig" \
LANG=en_US.UTF-8 \
meson --prefix=/usr          \
      --sysconfdir=/etc      \
      --localstatedir=/var   \
      -Dblkid=true           \
      -Dbuildtype=release    \
      -Ddefault-dnssec=no    \
      -Dfirstboot=false	     \
      -Dinstall-tests=false  \
      -Dkmod-path=/bin/kmod  \
      -Dldconfig=false       \
      -Dmount-path=/bin/mount \
      -Drootprefix=           \
      -Drootlibdir=/lib       \
      -Dsplit-user=true       \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false        \
      -Dumount-path=/bin/umount \
      -Db_lto=false           \
      -Drpmmacrosdir=no       \
      ..
LANG=en_US.UTF-8 ninja || exit 1
LANG=en_US.UTF-8 ninja install || exit 1
rm -f /usr/bin/xsltproc
systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-time-wait-sync.service
rm -fv /usr/lib/lib{blkid,uuid,mount}.so*
cd $LFS/sources
rm -rf systemd-244

#-----
echo "# 6.74. D-Bus-1.12.16"
tar -xf dbus-1.12.16.tar.gz
cd dbus-1.12.16
./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.12.16 \
            --with-console-auth-dir=/run/console
make || exit 1
make install || exit 1
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
ln -sfv /etc/machine-id /var/lib/dbus
cd $LFS/sources
rm -rf dbus-1.12.16

#-----
echo "# 6.75. Procps-ng-3.3.15"
tar -xf procps-ng-3.3.15.tar.xz
cd procps-ng-3.3.15
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd
make || exit 1
make install || exit 1
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd $LFS/sources
rm -rf procps-ng-3.3.15

#-----
echo "# 6.76. util-linux-2.35.1"
tar -xf util-linux-2.35.1.tar.xz
cd util-linux-2.35.1
mkdir -pv /var/lib/hwclock
rm -vf /usr/include/{blkid,libmount,uuid}
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.35.1 \
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
rm -rf util-linux-2.35.1

#-----
echo "# 6.77. E2fsprogs-1.45.5"
tar -xf e2fsprogs-1.45.5.tar.gz
cd e2fsprogs-1.45.5
mkdir -v build && cd build
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make || exit 1
make install || exit 1
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
cd $LFS/sources
rm -rf e2fsprogs-1.45.5


#-----
echo "Set root password:"
passwd root

echo "Continue to 6.79: Stripping Again"
echo 

echo ""
echo "=== End of Chapter 6 ==="
echo ""


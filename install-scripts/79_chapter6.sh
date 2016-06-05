#!/bin/bash

if [[ "$(whoami)" != "root" ]] ; then
   echo "Not running as root! Exiting..."
   return;
fi

if ! [[ -d /tools ]]; then
   echo "/tools not found. Maybe not under chroot?"
   return;
fi

cd /sources

echo "# 6.7. Linux API Headers"
tar -xf linux-4.4.8.tar.xz
cd linux-4.4.8
make mrproper || exit 1
make INSTALL_HDR_PATH=dest headers_install || exit 1
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
cd /sources
rm -rf linux-4.4.8

#-----
echo "# 6.8. Man-pages-4.04"
tar -xf man-pages-4.04.tar.xz
cd man-pages-4.04
make install || exit 1
cd /sources
rm -rf man-pages-4.04

#-----
echo "# 6.9. Glibc-2.23"
tar -xf glibc-2.23.tar.xz
cd glibc-2.23
patch -Np1 -i ../glibc-2.23-fhs-1.patch
mkdir -v build && cd build
../configure    \
   --prefix=/usr          \
   --disable-profile      \
   --enable-kernel=2.6.32 \
   --enable-obsolete-rpc
make || exit 1
touch /etc/ld.so.conf
make install || exit 1

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../glibc-2.22/nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../glibc-2.22/nscd/nscd.service /lib/systemd/system/nscd.service

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

hosts: files dns myhostname
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# 6.9.2.2
tar -xf ../../tzdata2016a.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica  \
      asia australasia backward pacificnew systemv; do
   zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
   zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
   zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

cp -v /usr/share/zoneinfo/Canada/Eastern /etc/localtime

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

cd /sources
rm -rf glibc-2.23

#-----
echo "# 6.10. Adjusting the Toolchain"
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
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

#-----
echo "# 6.11. Zlib-1.2.8"
tar -xf zlib-1.2.8.tar.xz
cd zlib-1.2.8
./configure --prefix=/usr
make || exit 1
make install || exit 1
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd /sources
rm -rf zlib-1.2.8

#-----
echo "# 6.12. File-5.25"
tar -xf file-5.25.tar.gz
cd file-5.25
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf file-5.25

#-----
echo "# 6.13. Binutils-2.26"
tar -xf binutils-2.26.tar.bz2
cd binutils-2.26
patch -Np1 -i ../binutils-2.26-upstream_fix-2.patch
mkdir -v build && cd build
../configure --prefix=/usr  \
             --enable-shared \
             --disable-werror
make tooldir=/usr || exit 1
make tooldir=/usr install || exit 1
cd /sources
rm -rf binutils-2.26

#-----
echo "# 6.14. GMP-6.1.0"
tar -xf gmp-6.1.0.tar.xz
cd gmp-6.1.0
./configure --prefix=/usr \
            --enable-cxx  \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.0
make || exit 1
make install || exit 1
cd /sources
rm -rf gmp-6.1.0

#-----
echo "# 6.15. MPFR-3.1.3"
tar -xf mpfr-3.1.3.tar.xz
cd mpfr-3.1.3
patch -Np1 -i ../mpfr-3.1.3-upstream_fixes-2.patch
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.3
make || exit 1
make install || exit 1
cd /sources
rm -rf mpfr-3.1.3

#-----
echo "# 6.16. MPC-1.0.3"
tar -xf mpc-1.0.3.tar.gz
cd mpc-1.0.3
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.0.3
make || exit 1
make install || exit 1
cd /sources
rm -rf mpc-1.0.3

#-----
echo "# 6.17. GCC-5.3.0"
tar -xf gcc-5.3.0.tar.bz2
cd gcc-5.3.0
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
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/5.3.0/liblto_plugin.so /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources

cc dummy.c -v -Wl,--verbose &> log-6.17_long.out
readelf -l a.out | grep ': /lib' > log-6.17.out
rm -v a.out

echo "Check log-6.17.out and log-6.17_long.out"
echo
read -p "Press Y to contiue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi

rm -rf gcc-5.3.0

#-----
echo "# 6.18. Bzip2-1.0.6"
tar -xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
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
cd /sources
rm -rf bzip2-1.0.6

#-----
echo "# 6.19. Pkg-config-0.29"
tar -zxf pkg-config-0.29.tar.gz
cd pkg-config-0.29
./configure --prefix=/usr         \
            --with-internal-glib  \
            --disable-host-tool   \
            --docdir=/usr/share/doc/pkg-config-0.29
make || exit 1
make install || exit 1
cd /sources
rm -rf pkg-config-0.29

#-----
echo "# 6.20. Ncurses-6.0"
tar -xf ncurses-6.0.tar.gz
cd ncurses-6.0
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

cd /sources
rm -rf ncurses-6.0

#-----
echo "6.21. Attr-2.4.47"
tar -xf attr-2.4.47.src.tar.gz
cd attr-2.4.47
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i -e "/SUBDIRS/s|man[25]||" man/Makefile
./configure --prefix=/usr --disable-static
make || exit 1
make install install-dev install-lib || exit 1
chmod -v 755 /usr/lib/libattr.so
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd /sources
rm -rf attr-2.4.47

#-----
echo "6.22. Acl-2.2.52"
tar -xf acl-2.2.52.src.tar.gz
cd acl-2.2.52
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" libacl/__acl_to_any_text.c
./configure --prefix=/usr \
            --disable-static \
            --libexecdir=/usr/lib
make || exit 1
make install install-dev install-lib || exit 1
chmod -v 755 /usr/lib/libacl.so
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd /sources
rm -rf acl-2.2.52

#-----
echo "6.23. Libcap-2.25"
tar -xf libcap-2.25.tar.xz
cd libcap-2.25
sed -i '/install.*STALIBNAME/d' libcap/Makefile
make || exit 1
make RAISE_SETFCAP=no prefix=/usr install || exit 1
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd /sources
rm -rf libcap-2.25

#-----
echo "# 6.24. Sed-4.2.2"
tar -xf sed-4.2.2.tar.bz2
cd sed-4.2.2
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2
make || exit 
make install || exit 1
cd /sources
rm -rf sed-4.2.2

#-----
echo "# 6.25. Shadow-4.2.1"
tar -xf shadow-4.2.1.tar.xz
cd shadow-4.2.1
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
mv -v /usr/bin/passwd /bin
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here
cd /sources
rm -rf shadow-4.2.1

#-----
echo "# 6.26. Psmisc-22.21"
tar -xf psmisc-22.21.tar.gz
cd psmisc-22.21
./configure --prefix=/usr
make || exit 1
make install || exit 1
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd /sources
rm -rf psmisc-22.21

#-----
echo "# 6.27. Iana-etc-2.30"
tar -xf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make || exit 1
make install || exit 1
cd /sources
rm -rf iana-etc-2.30

#-----
echo "# 6.28. M4-1.4.17"
tar -xf m4-1.4.17.tar.xz
cd m4-1.4.17
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf m4-1.4.17

#-----
echo "# 6.29. Bison-3.0.4"
tar -xf bison-3.0.4.tar.xz
cd bison-3.0.4
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4
make || exit 1
make install || exit 1
cd /sources
rm -rf bison-3.0.4

#-----
echo "# 6.30. Flex-2.6.0"
tar -xf flex-2.6.0.tar.xz
cd flex-2.6.0
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.0
make || exit 1
make install || exit 1
ln -sv flex /usr/bin/lex
cd /sources
rm -rf flex-2.6.0

#-----
echo "# 6.31. Grep-2.23"
tar -xf grep-2.23.tar.xz
cd grep-2.23
./configure --prefix=/usr --bindir=/bin
make || exit 1
make install || exit 1
cd /sources
rm -rf grep-2.23

#-----
echo "# 6.32. Readline-6.3"
tar -xf readline-6.3.tar.gz
cd readline-6.3
patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-6.3
make SHLIB_LIBS=-lncurses || exit 1
make SHLIB_LIBS=-lncurses install || exit 1
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
cd /sources
rm -rf readline-6.3

#-----
echo "# 6.33. Bash-4.3.30"
tar -xf bash-4.3.30.tar.gz
cd bash-4.3.30
patch -Np1 -i ../bash-4.3.30-upstream_fixes-3.patch
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/bash-4.3.30 \
            --without-bash-malloc               \
            --with-installed-readline
make || exit 1
make install || exit 1
mv -vf /usr/bin/bash /bin
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd /sources
rm -rf bash-4.3.30

#-----
echo "# 6.34. Bc-1.06.95"
tar -xf bc-1.06.95.tar.bz2
cd bc-1.06.95
patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make || exit 1
make install || exit 1
cd /sources
rm -rf bc-1.06.95

#-----
echo "# 6.35. Libtool-2.4.6"
tar -xf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf libtool-2.4.6

#-----
echo "# 6.36. GDBM-1.11"
tar -xf gdbm-1.11.tar.gz
cd gdbm-1.11
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat
make || exit 1
make install || exit 1
cd /sources
rm -rf gdbm-1.11

#-----
echo "6.37. Gperf-3.0.4"
tar -xf gperf-3.0.4.tar.gz
cd gperf-3.0.4
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
make || exit 1
make install || exit 1
cd /sources
rm -rf gperf-3.0.4

#-----
echo "6.38. Expat-2.1.0"
tar -xf expat-2.1.0.tar.gz
cd expat-2.1.0
./configure --prefix=/usr --disable-static
make || exit 1
make install || exit 1
cd /sources
rm -rf expat-2.1.0

#-----
echo "# 6.39. Inetutils-1.9.4"
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
cd /sources
rm -rf inetutils-1.9.4

#-----
echo "# 6.40. Perl-5.22.1"
tar -xf perl-5.22.1.tar.bz2
cd perl-5.22.1
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make || exit 1
make install || exit 1
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -rf perl-5.22.1

#-----
echo "6.41. XML::Parser-2.44"
tar -xf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
perl Makefile.PL
make || exit 1
make install || exit 1
cd /sources
rm -rf XML-Parser-2.44

#-----
echo "6.42. Intltool-0.51.0"
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf intltool-0.51.0

#-----
echo "# 6.43. Autoconf-2.69"
tar -xf autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf autoconf-2.69

#-----
echo "# 6.44. Automake-1.15"
tar -xf automake-1.15.tar.xz
cd automake-1.15
sed -i 's:/\\\${:/\\\$\\{:' bin/automake.in
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15
make || exit 1
make install || exit 1
cd /sources
rm -rf automake-1.15

#-----
echo "# 6.45. Xz-5.2.2"
tar -xf xz-5.2.2.tar.xz
cd xz-5.2.2
sed -e '/mf\.buffer = NULL/a next->coder->mf.size = 0;' -i src/liblzma/lz/lz_encoder.c
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.2
make || exit 1
make install || exit 1
mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd /sources
rm -rf xz-5.2.2

#-----
echo "# 6.46. Kmod-22"
tar -xf kmod-22.tar.xz
cd kmod-22
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
ln -sv kmod /bin/lsmod
cd /sources
rm -rf kmod-22

#-----
echo "# 6.47. Gettext-0.19.7"
tar -xf gettext-0.19.7.tar.xz
cd gettext-0.19.7
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.7
make || exit 1
make install || exit 1
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources
rm -rf gettext-0.19.7

#-----
echo "# 6.48 Systemd-229"
tar -xf systemd-229.tar.xz
cd systemd-229
sed -i "s:blkid/::" $(grep -rl "blkid/blkid.h")
patch -Np1 -i ../systemd-229-compat-1.patch
autoreconf -fi
cat > config.cache << "EOF"
KILL=/bin/kill
MOUNT_PATH=/bin/mount
UMOUNT_PATH=/bin/umount
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include/blkid"
HAVE_LIBMOUNT=1
MOUNT_LIBS="-lmount"
MOUNT_CFLAGS="-I/tools/include/libmount"
cc_cv_CFLAGS__flto=no
XSLTPROC="/usr/bin/xsltproc"
EOF
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --localstatedir=/var   \
            --config-cache         \
            --with-rootprefix=     \
            --with-rootlibdir=/lib \
            --enable-split-usr     \
            --disable-firstboot    \
            --disable-ldconfig     \
            --disable-sysusers     \
            --without-python       \
            --docdir=/usr/share/doc/systemd-229
make LIBRARY_PATH=/tools/lib || exit 1
make LIBRARY_PATH=/tools/lib install || exit 1

mv -v /usr/lib/libnss_{myhostname,mymachines,resolve}.so.2 /lib
rm -rfv /usr/lib/rpm
for tool in runlevel reboot shutdown poweroff halt telinit; do
     ln -sfv ../bin/systemctl /sbin/${tool}
done
ln -sfv ../lib/systemd/systemd /sbin/init
systemd-machine-id-setup
cd /sources
rm -rf systemd-229

#-----
echo "# 6.49. Procps-ng-3.3.11"
tar -xf procps-ng-3.3.11.tar.xz
cd procps-ng-3.3.11
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.11 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd
make || exit 1
make install || exit 1
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd /sources
rm -rf procps-ng-3.3.11

#-----
echo "# 6.50. E2fsprogs-1.42.13"
tar -xf e2fsprogs-1.42.13.tar.gz
cd e2fsprogs-1.42.13
mkdir -v build && cd build
LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
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
make install-libs || exit 1
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
cd /sources
rm -rf e2fsprogs-1.42.13

#-----
echo "# 6.51. Coreutils-8.25"
tar -xf coreutils-8.25.tar.xz
cd coreutils-8.25
patch -Np1 -i ../coreutils-8.25-i18n-2.patch 
FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr            \
            --enable-no-install-program=kill,uptime
FORCE_UNSAFE_CONFIGURE=1 make || exit 1
make install || exit 1
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice,test} /bin
#mv -v /usr/bin/[ /bin
cd /sources
rm -rf coreutils-8.25

#-----
echo "# 6.52. Diffutils-3.3"
tar -xf diffutils-3.3.tar.xz
cd diffutils-3.3
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf diffutils-3.3

#-----
echo "# 6.53. Gawk-4.1.3"
tar -xf gawk-4.1.3.tar.xz
cd gawk-4.1.3
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf gawk-4.1.3

#-----
echo "# 6.54. Findutils-4.6.0"
tar -xf findutils-4.6.0.tar.gz
cd findutils-4.6.0
./configure --prefix=/usr --localstatedir=/var/lib/locate
make || exit 1
make install || exit 1
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
cd /sources
rm -rf findutils-4.6.0

#-----
echo "# 6.55. Groff-1.22.3"
tar -xf groff-1.22.3.tar.gz
cd groff-1.22.3
PAGE=letter ./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf groff-1.22.3

#-----
echo "# 6.56. GRUB-2.02~beta2"
tar -xf grub-2.02~beta2.tar.xz
cd grub-2.02~beta2
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror
make || exit 1
make install || exit 1
cd /sources
rm -rf grub-2.02~beta2

#-----
echo "# 6.57. Less-481"
tar -xf less-481.tar.gz
cd less-481
./configure --prefix=/usr --sysconfdir=/etc
make || exit 1
make install || exit 1
cd /sources
rm -rf less-481

#-----
echo "# 6.58. Gzip-1.6"
tar -xf gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/usr --bindir=/bin
make || exit 1
make install || exit 1
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
cd /sources
rm -rf gzip-1.6

#-----
echo "# 6.59. IPRoute2-4.4.0"
tar -xf iproute2-4.4.0.tar.xz
cd iproute2-4.4.0
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
rm -v doc/arpd.sgml
make || exit 1
make DOCDIR=/usr/share/doc/iproute2-4.4.0 install || exit 1
cd /sources
rm -rf iproute2-4.4.0

#-----
echo "# 6.60. Kbd-2.0.3"
tar -xf kbd-2.0.3.tar.xz
cd kbd-2.0.3
patch -Np1 -i ../kbd-2.0.3-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make || exit 1
make install || exit 1
cd /sources
rm -rf kbd-2.0.3

#-----
echo "# 6.61. Libpipeline-1.4.1"
tar -xf libpipeline-1.4.1.tar.gz
cd libpipeline-1.4.1
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf libpipeline-1.4.1

#-----
echo "# 6.62. Make-4.1"
tar -xf make-4.1.tar.bz2
cd make-4.1
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf make-4.1

#-----
echo "# 6.63. Patch-2.7.5"
tar -xf patch-2.7.5.tar.xz
cd patch-2.7.5
./configure --prefix=/usr
make || exit 1
make install || exit 1
cd /sources
rm -rf patch-2.7.5

#-----
echo "# 6.64. D-Bus-1.10.6"
tar -xf dbus-1.10.6.tar.gz
cd dbus-1.10.6
./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.10.6 \
            --with-console-auth-dir=/run/console
make || exit 1
make install || exit 1
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
ln -sfv /etc/machine-id /var/lib/dbus
cd /sources
rm -rf dbus-1.10.6

#-----
echo "# 6.65. util-linux-2.27.1"
tar -xf util-linux-2.27.1.tar.xz
cd util-linux-2.27.1
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.27.1 \
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
cd /sources
rm -rf util-linux-2.27.1

#-----
echo "# 6.66. Man-DB-2.7.5"
tar -xf man-db-2.7.5.tar.xz
cd man-db-2.7.5
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.7.5 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make || exit 1
make install || exit 1
sed -i "s:man root:root root:g" /usr/lib/tmpfiles.d/man-db.conf
cd /sources
rm -rf man-db-2.7.5

#-----
echo "# 6.67. Tar-1.28"
tar -xf tar-1.28.tar.xz
cd tar-1.28
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make || exit 1
make install || exit 1
cd /sources
rm -rf tar-1.28

#-----
echo "# 6.68. Texinfo-6.1"
tar -xf texinfo-6.1.tar.xz
cd texinfo-6.1
./configure --prefix=/usr
make || exit 1
make install || exit 1
make TEXMF=/usr/share/texmf install-tex || exit 1
cd /sources
rm -rf texinfo-6.1

#-----
echo "# 6.69. Vim-7.4"
tar -xf vim-7.4.tar.bz2
cd vim74
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make || exit 1
make install || exit 1
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
   ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4
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

if (&term == "iterm") || (&term == "putty")
   set background=dark
endif

" End /etc/vimrc
EOF
cd /sources
rm -rf vim74


#-----
echo "Set root password:"
passwd root

echo ">>> Remember to run:"
echo '    mv -v /usr/bin/[ /bin'

echo ""
echo "=== End of Chapter 6 ==="
echo ""


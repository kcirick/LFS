#!/bin/bash

if [[ "$(whoami)" != "root" ]] ; then
   echo "Not running as root! Exiting..."
   exit 
fi

cd $LFS/sources

if [[ $1 -eq 1 ]]; then
   "nothing to do"
fi

#-----
echo "# 8.3. Man-pages"
tar -xf man-pages-6.05.01.tar.xz
cd man-pages-6.05.01

rm -v man3/crypt*

make prefix=/usr install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf man-pages-6.05.01


#-----
echo "# 8.4. Iana-etc"
tar -xf iana-etc-20230810.tar.gz
cd iana-etc-20230810

cp services protocols /etc

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf iana-etc-20230810

#-----
echo "# 8.5. Glibc"
tar -xf glibc-2.38.tar.xz
cd glibc-2.38

patch -Np1 -i ../glibc-2.38-fhs-1.patch
#patch -Np1 -i ../glibc-2.38-memalign_fix-1.patch
patch -Np1 -i ../glibc-2.38-upstream_fixes-3.patch

mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr          \
             --disable-werror       \
             --enable-kernel=4.14    \
             --enable-stack-protector=strong \
             --with-headers=/usr/include     \
             libc_cv_slibdir=/lib

make || exit 1

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install || exit 1

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service

mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i en_CA -f ISO-8859-1 en_CA
localedef -i en_CA -f UTF-8 en_CA.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8

# 8.5.2
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

tar -xf ../../tzdata2023c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
      asia australasia backward; do
   zic -L /dev/null   -d $ZONEINFO       ${tz}
   zic -L /dev/null   -d $ZONEINFO/posix ${tz}
   zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/Canada/Eastern /etc/localtime

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
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf glibc-2.38


#-----
echo "# 8.6. Zlib"
tar -xf zlib-1.2.13.tar.xz
cd zlib-1.2.13

./configure --prefix=/usr

make || exit 1
make install || exit 1

rm -fv /usr/lib/libz.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf zlib-1.2.13

#-----
echo "# 8.7. Bzip2"
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8

patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so || exit 1
make clean
make || exit 1
make PREFIX=/usr install || exit 1

cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
   ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bzip2-1.0.8

#-----
echo "# 8.8. Xz"
tar -xf xz-5.4.4.tar.xz
cd xz-5.4.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.4

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf xz-5.4.4

#-----
echo "# 8.9. Zstd"
tar -xf zstd-1.5.5.tar.gz
cd zstd-1.5.5

make prefix=/usr || exit 1
make prefix=/usr install || exit 1

rm -v /usr/lib/libzstd.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf zstd-1.5.5

#-----
echo "# 8.10. File"
tar -xf file-5.45.tar.gz
cd file-5.45

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf file-5.45

#-----
echo "# 8.11. Readline"
tar -xf readline-8.2.tar.gz
cd readline-8.2

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

patch -Np1 -i ../readline-8.2-upstream_fix-1.patch

./configure --prefix=/usr    \
            --disable-static \
	         --with-curses    \
            --docdir=/usr/share/doc/readline-8.2

make SHLIB_LIBS="-lncursesw" || exit 1
make SHLIB_LIBS="-lncursesw" install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf readline-8.2

#-----
echo "# 8.12. M4"
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf m4-1.4.19

#-----
echo "# 8.13 BC"
tar -xf bc-6.6.0.tar.xz
cd bc-6.6.0

CC=gcc ./configure --prefix=/usr -G -O3 -r

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bc-6.6.0

#-----
echo "# 8.14. Flex"
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4

./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

make || exit 1
make install || exit 1

ln -sv flex /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf flex-2.6.4

#-----
echo "# 8.15 Tcl"
tar -xf tcl8.6.13-src.tar.gz
cd tcl8.6.13

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr \
	         --mandir=/usr/share/man 

make || exit 1

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR

make install || exit 1

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers

ln -sfv tclsh8.6 /usr/bin/tclsh

mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf tcl8.6.13

#-----
echo "# 8.16. Expect"
tar -xf expect5.45.4.tar.gz
cd expect5.45.4

./configure --prefix=/usr       \
            --with-tcl=/usr/lib \
	         --enable-shared     \
	         --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make || exit 1
make install || exit 1
ln -sfv expect5.45.4/libexpect5.45.4.so /usr/lib

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf expect5.45.4

#-----
echo "# 8.17. DejaGNU"
tar -xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3

mkdir -v build && cd build
../configure --prefix=/usr

makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make install || exit 1
install -v -dm755 /usr/share/doc/dejagnu-1.6.3
install -v -m644  doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf dejagnu-1.6.3

#-----
echo "# 8.18. Binutils"
tar -xf binutils-2.41.tar.xz
cd binutils-2.41

mkdir -v build && cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
	          --enable-gold       \
	          --enable-ld=default \
	          --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
	          --enable-64-bit-bfd \
	          --with-system-zlib

make tooldir=/usr || exit 1
make tooldir=/usr install || exit 1

rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf binutils-2.41

#-----
echo "# 8.19. GMP"
tar -xf gmp-6.3.0.tar.xz
cd gmp-6.3.0

./configure --prefix=/usr \
            --enable-cxx  \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gmp-6.3.0

#-----
echo "# 8.20. MPFR"
tar -xf mpfr-4.2.0.tar.xz
cd mpfr-4.2.0

sed -e 's/+01,234,567/+1,234,567 /' \
    -e 's/13.10Pd/13Pd/'            \
    -i tests/tsprintf.c

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.0

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf mpfr-4.2.0

#-----
echo "# 8.21. MPC"
tar -xf mpc-1.3.1.tar.gz
cd mpc-1.3.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf mpc-1.3.1

#-----
echo "8.22. Attr"
tar -xf attr-2.5.1.tar.gz
cd attr-2.5.1

./configure --prefix=/usr \
	         --disable-static \
	         --sysconfdir=/etc \
	         --docdir=/usr/share/doc/attr-2.5.1

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf attr-2.5.1

#-----
echo "8.23. Acl"
tar -xf acl-2.3.1.tar.xz
cd acl-2.3.1

./configure --prefix=/usr \
            --disable-static \
	         --docdir=/usr/share/doc/acl-2.3.1

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf acl-2.3.1

#-----
echo "8.24. Libcap"
tar -xf libcap-2.69.tar.xz
cd libcap-2.69

sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib || exit 1
make prefix=/usr lib=lib install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libcap-2.69

#-----
echo "# 8.25. Libxcrypt"
tar -xf libxcrypt-4.4.36.tar.xz
cd libxcrypt-4.4.36

./configure --prefix=/usr                 \
            --enable-hashes=strong,glibc  \
            --enable-obsolete-api=no      \
            --disable-static              \
            --disable-failure-tokens

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libxcrypt-4.4.36

#-----
echo "# 8.26. Shadow"
tar -xf shadow-4.13.tar.xz
cd shadow-4.13

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD YESCRYPT@' \
       -e 's@/var/spool/mail@/var/mail@' \
       -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
       -i etc/login.defs

touch /usr/bin/passwd
./configure --sysconfdir=/etc \
            --disable-static  \
            --with-{b,yes}crypt \
            --with-group-name-max-length=32

make || exit 1
make exec_prefix=/usr install || exit 1
make -C man install-man || exit 1

# 8.25.2 configuring shadow
pwconv
grpconv

mkdir -p /etc/default
useradd -D --gid 999

sed -i '/MAIL/s/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf shadow-4.13

#-----
echo "# 8.27. GCC"
tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0

case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
		    -i.orig gcc/config/i386/t-linux64
	;;
esac

mkdir -v build && cd build
../configure --prefix=/usr            \
	          LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

make || exit 1
make install || exit 1

chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr ../usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

cd $LFS/sources

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> log-8.27_long.out
readelf -l a.out | grep ': /lib' > log-8.27.out
rm -v a.out dummy.c

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

echo "Check log-8.27.out and log-8.27_long.out"
echo
read -p "Press Y to contiue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gcc-13.2.0

#-----
echo "# 8.28. Pkgconf"
tar -xf pkgconf-2.0.1.tar.xz
cd pkgconf-2.0.1

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/pkgconf-2.0.1

make || exit 1
make install || exit 1

ln -sv pkgconf /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf pkgconf-2.0.1

#-----
echo "# 8.29. Ncurses"
tar -xf ncurses-6.4.tar.gz
cd ncurses-6.4

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/share/pkgconfig

make || exit 1
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v dest/usr/lib/libncursesw.so.6.4
cp -av dest/* /

for lib in ncurses form panel menu ; do
   rm -vf                    /usr/lib/lib${lib}.so
   echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
   ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf ncurses-6.4

#-----
echo "# 8.30. Sed"
tar -xf sed-4.9.tar.xz
cd sed-4.9

./configure --prefix=/usr

make || exit 
make html || exit
make install || exit 1
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf sed-4.9

#-----
echo "# 8.31. Psmisc"
tar -xf psmisc-23.6.tar.xz
cd psmisc-23.6

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf psmisc-23.6

#-----
echo "# 8.32. Gettext"
tar -xf gettext-0.22.tar.xz
cd gettext-0.22

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22

make || exit 1
make install || exit 1
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gettext-0.22

#-----
echo "# 8.33. Bison"
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
echo "# 8.34. Grep"
tar -xf grep-3.11.tar.xz
cd grep-3.11

sed -i "s/echo/#echo/" src/egrep.sh

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf grep-3.11

#-----
echo "# 8.35. Bash"
tar -xf bash-5.2.15.tar.gz
cd bash-5.2.15

./configure --prefix=/usr              \
            --without-bash-malloc      \
            --with-installed-readline  \
            --docdir=/usr/share/doc/bash-5.2.15

make || exit 1
make install || exit 1
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bash-5.2.15

#-----
echo "# 8.36. Libtool"
tar -xf libtool-2.4.7.tar.xz
cd libtool-2.4.7

./configure --prefix=/usr

make || exit 1
make install || exit 1
rm -fv /usr/lib/libltdl.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libtool-2.4.7

#-----
echo "# 8.37. GDBM"
tar -xf gdbm-1.23.tar.gz
cd gdbm-1.23

./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gdbm-1.23

#-----
echo "8.38. Gperf"
tar -xf gperf-3.1.tar.gz
cd gperf-3.1

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gperf-3.1

#-----
echo "8.39. Expat"
tar -xf expat-2.5.0.tar.xz
cd expat-2.5.0

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.5.0

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf expat-2.5.0

#-----
echo "# 8.40. Inetutils"
tar -xf inetutils-2.4.tar.xz
cd inetutils-2.4

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
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
mv -v /usr/{,s}bin/ifconfig

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf inetutils-2.4

#-----
echo "# 8.41. Less"
tar -xf less-643.tar.gz
cd less-643

./configure --prefix=/usr --sysconfdir=/etc

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf less-643

#-----
echo "# 8.42. Perl"
tar -xf perl-5.38.0.tar.xz
cd perl-5.38.0

export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
		            -Dprivlib=/usr/lib/perl5/5.38/core_perl \
		            -Darchlib=/usr/lib/perl5/5.38/core_perl \
		            -Dsitelib=/usr/lib/perl5/5.38/site_perl \
		            -Dsitearch=/usr/lib/perl5/5.38/site_perl \
		            -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
		            -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib			\
		            -Dusethreads

make || exit 1
make install || exit 1
unset BUILD_ZLIB BUILD_BZIP2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf perl-5.38.0

#-----
echo "8.43. XML::Parser"
tar -xf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46

perl Makefile.PL
make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf XML-Parser-2.46

#-----
echo "8.44. Intltool"
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make || exit 1
make install || exit 1
#install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf intltool-0.51.0

#-----
echo "# 8.45. Autoconf"
tar -xf autoconf-2.71.tar.xz
cd autoconf-2.71

sed -e 's/SECONDS|/&SHLVL|/'               \
    -e '/BASH_ARGV=/a\        /^SHLVL=/ d' \
    -i.orig tests/local.at

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf autoconf-2.71

#-----
echo "# 8.46. Automake"
tar -xf automake-1.16.5.tar.xz
cd automake-1.16.5

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf automake-1.16.5

#-----
echo "# 8.47 OpenSSL"
tar -xf openssl-3.1.2.tar.gz
cd openssl-3.1.2

./config --prefix=/usr \
	      --openssldir=/etc/ssl \
	      --libdir=lib \
	      shared \
	      zlib-dynamic

make || exit 1
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install || exit 1

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.1.2
cp -vfr doc/* /usr/share/doc/openssl-3.1.2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf openssl-3.1.2

#-----
echo "# 8.48. Kmod"
tar -xf kmod-30.tar.xz
cd kmod-30

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib

make || exit 1
make install || exit 1

for target in depmod insmod modinfo modprobe rmmod; do
   ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf kmod-30

#-----
echo "# 8.49. Libelf from Elfutils"
tar -xf elfutils-0.189.tar.bz2
cd elfutils-0.189

./configure --prefix=/usr           \
            --disable-debuginfod    \
            --enable-libdebuginfod=dummy

make || exit 1
make -C libelf install || exit 1
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf elfutils-0.189

#----
echo "# 8.50. Libffi"
tar -xf libffi-3.4.4.tar.gz
cd libffi-3.4.4

./configure --prefix=/usr --disable-static --with-gcc-arch=native

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libffi-3.4.4

#-----
echo "# 8.51. Python"
tar -xf Python-3.11.4.tar.xz
cd Python-3.11.4

./configure --prefix=/usr \
	         --enable-shared \
	         --with-system-expat \
	         --with-system-ffi \
	         --enable-optimizations

make || exit 1
make install || exit 1

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.11.4/html
tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.11.4/html \
    -xvf ../python-3.11.4-docs-html.tar.bz2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf Python-3.11.4

#-----
echo "# 8.52. Flit-Core"
tar -xf flit_core-3.9.0.tar.gz
cd flit_core-3.9.0

pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist flit_core

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf flit_core-3.9.0

#-----
echo "# 8.53. Wheel"
tar -xf wheel-0.41.1.tar.gz
cd wheel-0.41.1

pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links=dist wheel

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf wheel-0.41.1

#-----
echo "# 8.54 Ninja"
tar -xf ninja-1.11.1.tar.gz
cd ninja-1.11.1

python3 configure.py --bootstrap

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf ninja-1.11.1

#-----
echo "# 8.55 Meson"
tar -xf meson-1.2.1.tar.gz
cd meson-1.2.1

pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf meson-1.2.1

#-----
echo "# 8.56. Coreutils"
tar -xf coreutils-9.3.tar.xz
cd coreutils-9.3

patch -Np1 -i ../coreutils-9.3-i18n-1.patch 

# CVE-2024-0684 fix
sed -e '/n_out += n_hold/,+4 s|.*bufsize.*|//&|' -i src/split.c

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr            \
            --enable-no-install-program=kill,uptime

make || exit 1
make install || exit 1

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf coreutils-9.3

#-----
echo "# 8.57 Check"
tar -xf check-0.15.2.tar.gz
cd check-0.15.2

./configure --prefix=/usr --disable-static

make || exit 1
make docdir=/usr/share/doc/check-0.15.2 install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf check-0.15.2

#-----
echo "# 8.58. Diffutils"
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf diffutils-3.10

#-----
echo "# 8.59. Gawk"
tar -xf gawk-5.2.2.tar.xz
cd gawk-5.2.2

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr

make || exit 1
make LN='ln -f' install || exit 1
ln -sv gawk.1 /usr/share/man/man1/awk.1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gawk-5.2.2

#-----
echo "# 8.60. Findutils"
tar -xf findutils-4.9.0.tar.xz
cd findutils-4.9.0

./configure --prefix=/usr --localstatedir=/var/lib/locate

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf findutils-4.9.0

#-----
echo "# 8.61. Groff"
tar -xf groff-1.23.0.tar.gz
cd groff-1.23.0

PAGE=letter ./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf groff-1.23.0

#-----
echo "# 8.62. GRUB"
tar -xf grub-2.06.tar.xz
cd grub-2.06

patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make || exit 1
make install || exit 1
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf grub-2.06

#-----
echo "# 8.63. Gzip"
tar -xf gzip-1.12.tar.xz
cd gzip-1.12

./configure --prefix=/usr 

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gzip-1.12

#-----
echo "# 8.64 IPRoute2"
tar -xf iproute2-6.4.0.tar.xz
cd iproute2-6.4.0

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns || exit 1
make SBINDIR=/usr/sbin install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf iproute2-6.4.0

#-----
echo "# 8.65. Kbd"
tar -xf kbd-2.6.1.tar.xz
cd kbd-2.6.1

patch -Np1 -i ../kbd-2.6.1-backspace-1.patch

sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf kbd-2.6.1

#-----
echo "# 8.66. Libpipeline"
tar -xf libpipeline-1.5.7.tar.gz
cd libpipeline-1.5.7

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libpipeline-1.5.7

#-----
echo "# 8.67. Make"
tar -xf make-4.4.1.tar.gz
cd make-4.4.1

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf make-4.4.1

#-----
echo "# 8.68. Patch"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf patch-2.7.6

#-----
echo "# 8.69. Tar"
tar -xf tar-1.35.tar.xz
cd tar-1.35

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr 

make || exit 1
make install || exit 1
make -C doc install-html docdir=/usr/share/doc/tar-1.35 || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf tar-1.35

#-----
echo "# 8.70. Texinfo"
tar -xf texinfo-7.0.3.tar.xz
cd texinfo-7.0.3

./configure --prefix=/usr

make || exit 1
make install || exit 1
make TEXMF=/usr/share/texmf install-tex || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf texinfo-7.0.3

#-----
echo "# 8.71. Vim"
tar -xf vim-9.0.1677.tar.gz
cd vim-9.0.1677

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr

make || exit 1
make install || exit 1

ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
   ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.1677

# 8.69.2 configuring vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing setting, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=

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
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf vim-9.0.1677

#-----
echo "# 8.72 MarkupSafe"
tar -xf MarkupSafe-2.1.3.tar.gz
cd MarkupSafe-2.1.3

pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist Markupsafe

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf MarkupSafe-2.1.3

#-----
echo "# 8.73 Jinja2"
tar -xf Jinja2-3.1.2.tar.gz
cd Jinja2-3.1.2

pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist Jinja2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf Jinja2-3.1.2

#-----
echo "# 8.74. Systemd"
tar -xf systemd-254.tar.gz
cd systemd-254

sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in

mkdir -p build ; cd build
meson setup \
      --prefix=/usr          \
      --buildtype=release    \
      -Ddefault-dnssec=no    \
      -Dfirstboot=false	     \
      -Dinstall-tests=false  \
      -Dldconfig=false       \
      -Dsysusers=false        \
      -Drpmmacrosdir=no       \
      -Dhomed=false           \
      -Duserdb=false          \
      -Dman=false             \
      -Dmode=release          \
      -Dpamconfdir=no         \
      -Ddev-kvm-mode=0660     \
      -Ddocdir=/usr/share/doc/systemd-254 \
      .. &> log.txt

ninja || exit 1
ninja install || exit 1

tar -xf ../../ systemd-man-pages-254.tar.xz \
      --no-same-owner --strip-components=1 \
      -C /usr/share/man

systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-sysupdate{,-reboot}

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf systemd-254

#-----
echo "# 8.75. D-Bus"
tar -xf dbus-1.14.8.tar.xz
cd dbus-1.14.8

./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --runstatedir=/run                  \
            --enable-user-session               \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.14.8 \
            --with-system-socket=/run/dbus/system_bus_socket

make || exit 1
make install || exit 1

ln -sfv /etc/machine-id /var/lib/dbus

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf dbus-1.14.8

#-----
echo "# 8.76. Man-DB"
tar -xf man-db-2.11.2.tar.xz
cd man-db-2.11.2

./configure --prefix=/usr                          \
            --docdir=/usr/share/doc/man-db-2.11.2  \
            --sysconfdir=/etc                      \
            --disable-setuid                       \
	         --enable-cache-owner=bin               \
            --with-browser=/usr/bin/lynx           \
            --with-vgrind=/usr/bin/vgrind          \
            --with-grap=/usr/bin/grap

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf man-db-2.11.2

#-----
echo "# 8.77. Procps-ng"
tar -xf procps-ng-4.0.3.tar.xz
cd procps-ng-4.0.3

./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-4.0.3  \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf procps-ng-4.0.3

#-----
echo "# 8.78. util-linux"
tar -xf util-linux-2.39.1.tar.xz
cd util-linux-2.39.1

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.39.1 \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
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
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf util-linux-2.39.1

#-----
echo "# 8.79. E2fsprogs"
tar -xf e2fsprogs-1.47.0.tar.gz
cd e2fsprogs-1.47.0

mkdir -v build && cd build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make || exit 1
make install || exit 1
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf e2fsprogs-1.47.0


#-----
echo "Set root password:"
passwd root

echo "Continue to 8.81: Stripping"
echo 

echo ""
echo "=== End of Chapter 8 ==="
echo ""


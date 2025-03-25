#!/bin/bash

if [[ "$(whoami)" != "root" ]] ; then
   echo "Not running as root! Exiting..."
   exit
fi

cd $LFS/sources

if [[ $1 -eq 1 ]]; then
   echo "nothing to do"


#-----
echo "# 8.3. Man-pages"
tar -xf man-pages-6.12.tar.xz
cd man-pages-6.12

rm -v man3/crypt*

make -R GIT=false prefix=/usr install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf man-pages-6.12


#-----
echo "# 8.4. Iana-etc"
tar -xf iana-etc-20250123.tar.gz
cd iana-etc-20250123

cp services protocols /etc

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf iana-etc-20250123

#-----
echo "# 8.5. Glibc"
tar -xf glibc-2.41.tar.xz
cd glibc-2.41

patch -Np1 -i ../glibc-2.41-fhs-1.patch

mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                   \
             --disable-werror                \
             --enable-kernel=5.4             \
             --enable-stack-protector=strong \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib

make || exit 1

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install || exit 1

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i en_CA -f ISO-8859-1 en_CA
localedef -i en_CA -f UTF-8 en_CA.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8

# 8.5.2
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2025a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
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
rm -rf glibc-2.41

#-----
echo "# 8.6. Zlib"
tar -xf zlib-1.3.1.tar.gz
cd zlib-1.3.1

./configure --prefix=/usr

make || exit 1
make install || exit 1

rm -fv /usr/lib/libz.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf zlib-1.3.1

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
tar -xf xz-5.6.4.tar.xz
cd xz-5.6.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.4

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf xz-5.6.4

#-----
echo "# 8.9 Lz4"
tar -xf lz4-1.10.0.tar.gz
cd lz4-1.10.0

make BUILD_STATIC=no PREFIX=/usr

make BUILD_STATIC=no PREFIX=/usr install

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf lz4-1.10.0

#-----
echo "# 8.10. Zstd"
tar -xf zstd-1.5.7.tar.gz
cd zstd-1.5.7

make prefix=/usr || exit 1
make prefix=/usr install || exit 1

rm -v /usr/lib/libzstd.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf zstd-1.5.7

#-----
echo "# 8.11. File"
tar -xf file-5.46.tar.gz
cd file-5.46

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf file-5.46

#-----
echo "# 8.12. Readline"
tar -xf readline-8.2.13.tar.gz
cd readline-8.2.13

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

./configure --prefix=/usr    \
            --disable-static \
	    --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13

make SHLIB_LIBS="-lncursesw" || exit 1
make SHLIB_LIBS="-lncursesw" install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf readline-8.2.13

#-----
echo "# 8.13. M4"
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
echo "# 8.14 BC"
tar -xf bc-7.0.3.tar.xz
cd bc-7.0.3

CC=gcc ./configure --prefix=/usr -G -O3 -r

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bc-7.0.3

#-----
echo "# 8.15. Flex"
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4

./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/flex-2.6.4  \
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
echo "# 8.16 Tcl"
tar -xf tcl8.6.16-src.tar.gz
cd tcl8.6.16

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath

make || exit 1

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"            \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh

unset SRCDIR

make install || exit 1

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers || exit 1

ln -sfv tclsh8.6 /usr/bin/tclsh

mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf tcl8.6.16

#-----
echo "# 8.17. Expect"
tar -xf expect5.45.4.tar.gz
cd expect5.45.4

patch -Np1 -i ../expect-5.45.4-gcc14-1.patch

./configure --prefix=/usr                 \
            --with-tcl=/usr/lib           \
	    --enable-shared               \
	    --disable-rpath		  \
	    --mandir=/usr/share/man       \
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
echo "# 8.18. DejaGNU"
tar -xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3

mkdir -v build && cd build
../configure --prefix=/usr

makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make install || exit 1
#install -v -dm755 /usr/share/doc/dejagnu-1.6.3
#install -v -m644  doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf dejagnu-1.6.3

#-----
echo "# 8.19. Pkgconf"
tar -xf pkgconf-2.3.0.tar.xz
cd pkgconf-2.3.0

./configure --prefix=/usr           \
            --disable-static        \
            --docdir=/usr/share/doc/pkgconf-2.3.0

make || exit 1
make install || exit 1

ln -sv pkgconf /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf pkgconf-2.3.0

#-----
echo "# 8.20. Binutils"
tar -xf binutils-2.44.tar.xz
cd binutils-2.44

mkdir -v build && cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
	     --enable-ld=default \
	     --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
	     --enable-64-bit-bfd \
	     --enable-new-dtags  \
	     --with-system-zlib  \
             --enable-default-hash-style=gnu

make tooldir=/usr || exit 1
make tooldir=/usr install || exit 1

rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
	/usr/share/doc/gprofng/

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf binutils-2.44

#-----
echo "# 8.21. GMP"
tar -xf gmp-6.3.0.tar.xz
cd gmp-6.3.0

./configure --prefix=/usr     \
            --enable-cxx      \
            --disable-static  \
            --docdir=/usr/share/doc/gmp-6.3.0

make || exit 1
#make html || exit 1
make install || exit 1
#make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gmp-6.3.0

#-----
echo "# 8.22. MPFR"
tar -xf mpfr-4.2.1.tar.xz
cd mpfr-4.2.1

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1

make || exit 1
#make html || exit 1
make install || exit 1
#make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf mpfr-4.2.1

#-----
echo "# 8.23. MPC"
tar -xf mpc-1.3.1.tar.gz
cd mpc-1.3.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1

make || exit 1
#make html || exit 1
make install || exit 1
#make install-html || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf mpc-1.3.1

#-----
echo "8.24. Attr"
tar -xf attr-2.5.2.tar.gz
cd attr-2.5.2

./configure --prefix=/usr     \
	         --disable-static  \
	         --sysconfdir=/etc \
	         --docdir=/usr/share/doc/attr-2.5.2

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf attr-2.5.2

#-----
echo "8.25. Acl"
tar -xf acl-2.3.2.tar.xz
cd acl-2.3.2

./configure --prefix=/usr     \
            --disable-static  \
	         --docdir=/usr/share/doc/acl-2.3.2

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf acl-2.3.2

#-----
echo "8.26. Libcap"
tar -xf libcap-2.73.tar.xz
cd libcap-2.73

sed -i '/install -m.*STA/d' libcap/Makefile

make prefix=/usr lib=lib || exit 1
make prefix=/usr lib=lib install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libcap-2.73

#-----
echo "# 8.27. Libxcrypt"
tar -xf libxcrypt-4.4.38.tar.xz
cd libxcrypt-4.4.38

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
rm -rf libxcrypt-4.4.38

#-----
echo "# 8.28. Shadow"
tar -xf shadow-4.17.3.tar.xz
cd shadow-4.17.3

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD YESCRYPT@' \
       -e 's@/var/spool/mail@/var/mail@' \
       -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
       -i etc/login.defs

touch /usr/bin/passwd
./configure --sysconfdir=/etc    \
            --disable-static     \
            --with-{b,yes}crypt  \
            --without-libbsd     \
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
rm -rf shadow-4.17.3

#-----
echo "# 8.29. GCC"
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0

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
	     --enable-host-pie	      \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

make || exit 1
make install || exit 1

chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

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
rm -rf gcc-14.2.0

#-----
echo "# 8.30. Ncurses"
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make || exit 1
make DESTDIR=$PWD/dest install || exit 1

install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
   ln -sfv lib${lib}w.so   /usr/lib/lib${lib}.so
   ln -sfv ${lib}w.pc      /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so     /usr/lib/libcurses.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf ncurses-6.5

#-----
echo "# 8.31. Sed"
tar -xf sed-4.9.tar.xz
cd sed-4.9

./configure --prefix=/usr

make || exit 
#make html || exit
make install || exit 1
#install -d -m755           /usr/share/doc/sed-4.9
#install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf sed-4.9

#-----
echo "# 8.32. Psmisc"
tar -xf psmisc-23.7.tar.xz
cd psmisc-23.7

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf psmisc-23.7

#-----
echo "# 8.33. Gettext"
tar -xf gettext-0.24.tar.xz
cd gettext-0.24

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.24

make || exit 1
make install || exit 1
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gettext-0.24

#-----
echo "# 8.34. Bison"
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
echo "# 8.35. Grep"
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
echo "# 8.36. Bash"
tar -xf bash-5.2.37.tar.gz
cd bash-5.2.37

./configure --prefix=/usr              \
            --without-bash-malloc      \
            --with-installed-readline  \
            --docdir=/usr/share/doc/bash-5.2.37

make || exit 1
make install || exit 1
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf bash-5.2.37

#-----
echo "# 8.37. Libtool"
tar -xf libtool-2.5.4.tar.xz
cd libtool-2.5.4

./configure --prefix=/usr

make || exit 1
make install || exit 1
rm -fv /usr/lib/libltdl.a

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libtool-2.5.4

#-----
echo "# 8.38. GDBM"
tar -xf gdbm-1.24.tar.gz
cd gdbm-1.24

./configure --prefix=/usr     \
            --disable-static  \
            --enable-libgdbm-compat

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gdbm-1.24

#-----
echo "8.39. Gperf"
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
echo "8.40. Expat"
tar -xf expat-2.6.4.tar.xz
cd expat-2.6.4

./configure --prefix=/usr     \
            --disable-static  \
            --docdir=/usr/share/doc/expat-2.6.4

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf expat-2.6.4

#-----
echo "# 8.41. Inetutils"
tar -xf inetutils-2.6.tar.xz
cd inetutils-2.6

sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

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
rm -rf inetutils-2.6

#-----
echo "# 8.42. Less"
tar -xf less-668.tar.gz
cd less-668

./configure --prefix=/usr --sysconfdir=/etc

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf less-668

#-----
echo "# 8.43. Perl"
tar -xf perl-5.40.1.tar.xz
cd perl-5.40.1

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                           \
             -D prefix=/usr                                  \
             -D vendorprefix=/usr                            \
	     -D privlib=/usr/lib/perl5/5.40/core_perl        \
	     -D archlib=/usr/lib/perl5/5.40/core_perl        \
	     -D sitelib=/usr/lib/perl5/5.40/site_perl        \
	     -D sitearch=/usr/lib/perl5/5.40/site_perl       \
	     -D vendorlib=/usr/lib/perl5/5.40/vendor_perl    \
	     -D vendorarch=/usr/lib/perl5/5.40/vendor_perl   \
             -D man1dir=/usr/share/man/man1                  \
             -D man3dir=/usr/share/man/man3                  \
             -D pager="/usr/bin/less -isR"                   \
             -D useshrplib	                             \
	     -D usethreads

make || exit 1
make install || exit 1
unset BUILD_ZLIB BUILD_BZIP2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf perl-5.40.1

#-----
echo "8.44. XML::Parser"
tar -xf XML-Parser-2.47.tar.gz
cd XML-Parser-2.47

perl Makefile.PL

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf XML-Parser-2.47

#-----
echo "8.45. Intltool"
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
echo "# 8.46. Autoconf"
tar -xf autoconf-2.72.tar.xz
cd autoconf-2.72

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf autoconf-2.72

#-----
echo "# 8.47. Automake"
tar -xf automake-1.17.tar.xz
cd automake-1.17

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf automake-1.17

#-----
echo "# 8.48 OpenSSL"
tar -xf openssl-3.4.1.tar.gz
cd openssl-3.4.1

./config --prefix=/usr           \
	      --openssldir=/etc/ssl   \
	      --libdir=lib            \
	      shared                  \
	      zlib-dynamic

make || exit 1
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install || exit 1

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.4.1
#cp -vfr doc/* /usr/share/doc/openssl-3.1.2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf openssl-3.4.1

#-----
echo "# 8.49. Libelf from Elfutils"
tar -xf elfutils-0.192.tar.bz2
cd elfutils-0.192

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
rm -rf elfutils-0.192

#----
echo "# 8.50. Libffi"
tar -xf libffi-3.4.7.tar.gz
cd libffi-3.4.7

./configure --prefix=/usr --disable-static --with-gcc-arch=native

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libffi-3.4.7

#-----
echo "# Extra: Sqlite"
tar -xf sqlite-autoconf-3490100.tar.gz
cd sqlite-autoconf-3490100

./configure --prefix=/usr \
            --disable-static \
            --enable-fts{4,5} \
            CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1 \
                      -DSQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                      -DSQLITE_ENBALE_DBSTAT_VTAB=1     \
                      -DSQLITE_SECURE_DELETE=1"

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf sqlite-autoconf-3490100

#-----
echo "# 8.51. Python"
tar -xf Python-3.13.2.tar.xz
cd Python-3.13.2

./configure --prefix=/usr        \
	         --enable-shared      \
	         --with-system-expat  \
	         --enable-optimizations

make || exit 1
make install || exit 1

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

#install -v -dm755 /usr/share/doc/python-3.11.4/html
#tar --strip-components=1 \
#    --no-same-owner \
#    --no-same-permissions \
#    -C /usr/share/doc/python-3.11.4/html \
#    -xvf ../python-3.11.4-docs-html.tar.bz2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf Python-3.13.2

#-----
echo "# 8.52. Flit-Core"
tar -xf flit_core-3.11.0.tar.gz
cd flit_core-3.11.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist flit_core

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf flit_core-3.11.0

#-----
echo "# 8.53. Wheel"
tar -xf wheel-0.45.1.tar.gz
cd wheel-0.45.1

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist wheel

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf wheel-0.45.1

#-----
echo "# 8.54 Setuptools"
tar -xf setuptools-75.8.1.tar.gz
cd setuptools-75.8.1

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist setuptools

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf setuptools-75.8.1

#-----
echo "# 8.55 Ninja"
tar -xf ninja-1.12.1.tar.gz
cd ninja-1.12.1

python3 configure.py --bootstrap || exit 1

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
#install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf ninja-1.12.1

#-----
echo "# 8.56 Meson"
tar -xf meson-1.7.0.tar.gz
cd meson-1.7.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist meson

install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
#install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf meson-1.7.0

#-----
echo "# 8.57. Kmod"
tar -xf kmod-34.tar.xz
cd kmod-34

mkdir -p build
cd build
meson setup --prefix=/usr          \
            --sbindir=/usr/sbin    \
            --buildtype=release    \
            -D manpages=false ..

ninja || exit 1
ninja install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf kmod-34

#-----
echo "# 8.58. Coreutils"
tar -xf coreutils-9.6.tar.xz
cd coreutils-9.6

patch -Np1 -i ../coreutils-9.6-i18n-1.patch 

autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr --enable-no-install-program=kill,uptime

make || exit 1
make install || exit 1

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf coreutils-9.6

#-----
echo "# 8.59 Check"
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
echo "# 8.60. Diffutils"
tar -xf diffutils-3.11.tar.xz
cd diffutils-3.11

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf diffutils-3.11

#-----
echo "# 8.61. Gawk"
tar -xf gawk-5.3.1.tar.xz
cd gawk-5.3.1

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr

make || exit 1
make install || exit 1
ln -sv gawk.1 /usr/share/man/man1/awk.1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gawk-5.3.1

#-----
echo "# 8.62. Findutils"
tar -xf findutils-4.10.0.tar.xz
cd findutils-4.10.0

./configure --prefix=/usr --localstatedir=/var/lib/locate

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf findutils-4.10.0

#-----
echo "# 8.63. Groff"
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
echo "# Extra: mandoc  --> Skip"
#tar -xf mandoc-1.14.6.tar.gz
#cd mandoc-1.14.6

#./configure --prefix=/usr

#make || exit 1

#install -vm755 mandoc   /usr/bin
#install -vm644 mandoc.1 /usr/share/man/man1

#cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
#rm -rf mandoc-1.14.6

#-----
echo "# Extra: popt"
tar -xf popt-1.19.tar.gz
cd popt-1.19

./configure --prefix=/usr --disable-static

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf popt-1.19

#-----
echo "# Extra: efivar"
tar -xf efivar-39.tar.gz
cd efivar-39

make ENABLE_DOCS=0 || exit 1
make install ENABLE_DOCS=0 LIBDIR=/usr/lib || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf efivar-39

#-----
echo "# Extra: efibootmgr"
tar -xf efibootmgr-18.tar.gz
cd efibootmgr-18

make EFIDIR=LFS EFI_LOADER=grubx64.efi || exit 1
make install EFIDIR=LFS || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf efibootmgr-18


#-----
echo "# 8.63. GRUB for EFI"
tar -xf grub-2.12.tar.xz
cd grub-2.12

#mkdir -pv /usr/share/fonts/unifont
#gunzip -c ../unifont-16.0.01.pcf.gz > /usr/share/fonts/unifont/unifont.pcf

echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --with-platform=efi    \
            --target=x86_64        \
            --disable-werror

#unset TARGET_CC &&
make || exit 1
make install || exit 1

mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf grub-2.12

#-----
echo "# 8.65. Gzip"
tar -xf gzip-1.13.tar.xz
cd gzip-1.13

./configure --prefix=/usr 

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gzip-1.13

#-----
echo "# 8.66 IPRoute2"
tar -xf iproute2-6.13.0.tar.xz
cd iproute2-6.13.0

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns || exit 1
make SBINDIR=/usr/sbin install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf iproute2-6.13.0

#-----
echo "# 8.67. Kbd"
tar -xf kbd-2.7.1.tar.xz
cd kbd-2.7.1

patch -Np1 -i ../kbd-2.7.1-backspace-1.patch

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
rm -rf kbd-2.7.1

#-----
echo "# 8.68. Libpipeline"
tar -xf libpipeline-1.5.8.tar.gz
cd libpipeline-1.5.8

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf libpipeline-1.5.8

#-----
echo "# 8.69. Make"
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
echo "# 8.70. Patch"
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
echo "# 8.71. Tar"
tar -xf tar-1.35.tar.xz
cd tar-1.35

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

make || exit 1
make install || exit 1
#make -C doc install-html docdir=/usr/share/doc/tar-1.35 || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf tar-1.35

#-----
echo "# 8.72. Texinfo"
tar -xf texinfo-7.2.tar.xz
cd texinfo-7.2

./configure --prefix=/usr

make || exit 1
make install || exit 1
make TEXMF=/usr/share/texmf install-tex || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf texinfo-7.2

#-----
### SKIP vim : Install nano instead
#
#echo "# 8.71. Vim"
#tar -xf vim-9.0.1677.tar.gz
#cd vim-9.0.1677
#
#echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
#./configure --prefix=/usr
#
#make || exit 1
#make install || exit 1
#
#ln -sv vim /usr/bin/vi
#for L in /usr/share/man/{,*/}man1/vim.1; do
#   ln -sv vim.1 $(dirname $L)/vi.1
#done
#ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.1677
#
## 8.69.2 configuring vim
#cat > /etc/vimrc << "EOF"
#" Begin /etc/vimrc
#
#" Ensure defaults are set before customizing setting, not after
#source $VIMRUNTIME/defaults.vim
#let skip_defaults_vim=1
#
#set nocompatible
#set backspace=2
#set mouse=
#
#set nu
#set ruler
#
#set tabstop=3
#set shiftwidth=3
#set expandtab
#
#syntax on
#
#if (&term == "xterm") || (&term == "putty")
#   set background=dark
#endif
#
#" End /etc/vimrc
#EOF
#
#cd $LFS/sources
#read -p "Press Y to continue: " answer
#if [ "$answer" != "Y" ]; then
#   exit
#fi
#rm -rf vim-9.0.1677

#-----
echo "# 8.73 nano"
tar -xf nano-8.3.tar.xz
cd nano-8.3

./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-utf8     \
            --docdir=/usr/share/doc/nano-8.3

make || exit 1
make install || exit 1

cat > /etc/nanorc << EOF
set autoindent
set constantshow
set fill 72
set historylog
set multibuffer
set nohelp
set positionlog
set quickblank
set regexp
EOF

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf nano-8.3

#-----
echo "# 8.74 MarkupSafe"
tar -xf markupsafe-3.0.2.tar.gz
cd markupsafe-3.0.2

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist Markupsafe

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf markupsafe-3.0.2

#-----
echo "# 8.75 Jinja2"
tar -xf jinja2-3.1.5.tar.gz
cd jinja2-3.1.5

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist Jinja2

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf Jinja2-3.1.5

#-----
echo "# 8.76. Systemd"
tar -xf systemd-257.3.tar.gz
cd systemd-257.3

sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in

mkdir -p build; cd build
meson setup --prefix=/usr          \
            --buildtype=release    \
            -D default-dnssec=no    \
            -D firstboot=false	     \
            -D install-tests=false  \
            -D ldconfig=false       \
            -D sysusers=false        \
            -D rpmmacrosdir=no       \
            -D homed=disabled        \
            -D userdb=false          \
            -D man=disabled          \
            -D mode=release          \
            -D pamconfdir=no         \
            -D dev-kvm-mode=0660     \
            -D nobody-group=nogroup  \
            -D sysupdate=disabled    \
            -D ukify=disabled        \
            -D docdir=/usr/share/doc/systemd-257.3 \
            .. &> log.txt

ninja || exit 1
ninja install || exit 1

tar -xf ../../ systemd-man-pages-257.3.tar.xz \
      --no-same-owner --strip-components=1 \
      -C /usr/share/man

systemd-machine-id-setup
systemctl preset-all

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf systemd-257.3

#-----
echo "# 8.77. D-Bus"
tar -xf dbus-1.16.0.tar.xz
cd dbus-1.16.0

mkdir build; cd build
meson setup --prefix=/usr \
	    --buildtype=release \
            --wrap-mode=nofallback ..

ninja || exit 1
ninja install || exit 1

ln -sfv /etc/machine-id /var/lib/dbus

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf dbus-1.16.0

#-----
echo "# 8.78. Man-DB"
tar -xf man-db-2.13.0.tar.xz
cd man-db-2.13.0

./configure --prefix=/usr                          \
            --docdir=/usr/share/doc/man-db-2.13.0  \
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
rm -rf man-db-2.13.0

fi #####

#-----
echo "# 8.79. Procps-ng"
tar -xf procps-ng-4.0.5.tar.xz
cd procps-ng-4.0.5

PKG_CONFIG_PATH=/usr/lib64/pkgconfig \
./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-4.0.5  \
            --disable-static                         \
            --disable-kill                           \
	    --enable-watch8bit			     \
            --with-systemd

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf procps-ng-4.0.5

#-----
echo "# 8.80. util-linux"
tar -xf util-linux-2.40.4.tar.xz
cd util-linux-2.40.4

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.40.4 \
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
	    --disable-liblastlog2 \
            --disable-static     \
            --without-python

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf util-linux-2.40.4

#-----
echo "# 8.81. E2fsprogs"
tar -xf e2fsprogs-1.47.2.tar.gz
cd e2fsprogs-1.47.2

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
rm -rf e2fsprogs-1.47.2


#-----
echo "Set root password:"
passwd root

echo "Continue to 8.82: Stripping"
echo

echo ""
echo "=== End of Chapter 8 ==="
echo ""

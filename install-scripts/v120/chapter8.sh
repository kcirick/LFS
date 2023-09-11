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
echo "# 8.3. Man-pages-5.08"
tar -xf man-pages-5.08.tar.xz
cd man-pages-5.08

make install || exit 1

cd $LFS/sources
rm -rf man-pages-5.08


#-----
echo "# 8.4 Tcl-8.6.10"
tar -xf tcl8.6.10-src.tar.gz
cd tcl8.6.10

tar -xf ../tcl8.6.10-html.tar.gz --strip-components=1

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr \
	    --mandir=/usr/share/man \
	    $([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)

make || exit 1

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.1|/usr/lib/tdbc1.1.1|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1|/usr/include|"            \
    -i pkgs/tdbc1.1.1/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.0|/usr/lib/itcl4.2.0|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.0/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.0|/usr/include|"            \
    -i pkgs/itcl4.2.0/itclConfig.sh
unset SRCDIR

make install || exit 1

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers

ln -sfv tclsh8.6 /usr/bin/tclsh

cd $LFS/sources
rm -rf tcl8.6.10

#-----
echo "# 8.5. Expect-5.45.4"
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
rm -rf expect5.45.4

#-----
echo "# 8.6. DejaGNU-1.6.2"
tar -xf dejagnu-1.6.2.tar.gz
cd dejagnu-1.6.2

./configure --prefix=/usr

makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  doc/dejagnu.texi

make install || exit 1
install -v -dm755 /usr/share/doc/dejagnu-1.6.2
install -v -m644  doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.2

cd $LFS/sources
rm -rf dejagnu-1.6.2

#-----
echo "# 8.7. Iana-etc-20200821"
tar -xf iana-etc-20200821.tar.gz
cd iana-etc-20200821

cp services protocols /etc

cd $LFS/sources
rm -rf iana-etc-20200821

#-----
echo "# 8.8. Glibc-2.32"
tar -xf glibc-2.32.tar.xz
cd glibc-2.32

patch -Np1 -i ../glibc-2.32-fhs-1.patch

mkdir -v build && cd build
../configure --prefix=/usr          \
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

# 8.8.2
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

tar -xf ../../tzdata2020a.tar.gz
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
rm -rf glibc-2.32

#-----
echo "# 8.9. Zlib-1.2.11"
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
echo "# 8.10. Bzip2-1.0.8"
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
echo "# 8.11. Xz-5.2.5"
tar -xf xz-5.2.5.tar.xz
cd xz-5.2.5

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.5

make || exit 1
make install || exit 1

mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

cd $LFS/sources
rm -rf xz-5.2.5

#-----
echo "# 8.12. Zstd-1.4.5"
tar -xf zstd-1.4.5.tar.gz
cd zstd-1.4.5

make || exit 1
make prefix=/usr install || exit 1

rm -v /usr/lib/libzstd.a
mv -v /usr/lib/libzstd.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so

cd $LFS/sources
rm -rf zstd-1.4.5

#-----
echo "# 8.13. File-5.39"
tar -xf file-5.39.tar.gz
cd file-5.39

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf file-5.39

#-----
echo "# 8.14. Readline-8.0"
tar -xf readline-8.0.tar.gz
cd readline-8.0

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr    \
            --disable-static \
	    --with-curses    \
            --docdir=/usr/share/doc/readline-8.0

make SHLIB_LIBS="-lncursesw" || exit 1
make SHLIB_LIBS="-lncursesw" install || exit 1

mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

cd $LFS/sources
rm -rf readline-8.0

#-----
echo "# 8.15. M4-1.4.18"
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
echo "# 8.16 BC-3.1.5"
tar -xf bc-3.1.5.tar.xz
cd bc-3.1.5

PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf bc-3.1.5

#-----
echo "# 8.17. Flex-2.6.4"
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4

./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make || exit 1
make install || exit 1
ln -sv flex /usr/bin/lex

cd $LFS/sources
rm -rf flex-2.6.4

#-----
echo "# 8.18. Binutils-2.35"
tar -xf binutils-2.35.tar.xz
cd binutils-2.35

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
rm -rf binutils-2.35

#-----
echo "# 8.19. GMP-6.2.0"
tar -xf gmp-6.2.0.tar.xz
cd gmp-6.2.0

./configure --prefix=/usr \
            --enable-cxx  \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.0

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
rm -rf gmp-6.2.0

#-----
echo "# 8.20. MPFR-4.1.0"
tar -xf mpfr-4.1.0.tar.xz
cd mpfr-4.1.0

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.2

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
rm -rf mpfr-4.1.0

#-----
echo "# 8.21. MPC-1.1.0"
tar -xf mpc-1.1.0.tar.gz
cd mpc-1.1.0

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make || exit 1
make html || exit 1
make install || exit 1
make install-html || exit 1

cd $LFS/sources
rm -rf mpc-1.1.0

#-----
echo "8.22. Attr-2.4.48"
tar -xf attr-2.4.48.tar.gz
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
echo "8.23. Acl-2.2.53"
tar -xf acl-2.2.53.tar.gz
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
echo "8.24. Libcap-2.42"
tar -xf libcap-2.42.tar.xz
cd libcap-2.42

sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile
make lib=lib || exit 1
make lib=lib PKGCONFIGDIR=/usr/lib/pkgconfig install || exit 1

chmod -v 755 /lib/libcap.so.2.42
mv -v /lib/libpsx.a /usr/lib
rm -v /lib/libcap.so
ln -sfv ../../lib/libcap.so.2 /usr/lib/libcap.so

cd $LFS/sources
rm -rf libcap-2.42

#-----
echo "# 8.25. Shadow-4.8.1"
tar -xf shadow-4.8.1.tar.xz
cd shadow-4.8.1

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd

touch /usr/bin/passwd
./configure --sysconfdir=/etc --with-group-name-max-length=32

make || exit 1
make install || exit 1

# 8.25.2 configuring shadow
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here

cd $LFS/sources
rm -rf shadow-4.8.1

#-----
echo "# 8.26. GCC-10.2.0"
tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -v build && cd build
../configure --prefix=/usr            \
	     LD=ld                    \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib

make || exit 1
make install || exit 1

rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/10.2.0/include-fixed/bits/

chown -v -R root:root /usr/lib/gcc/*linux-gnu/10.2.0/include{,-fixed}
ln -sv ../usr/bin/cpp /lib
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/10.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd $LFS/sources

cc dummy.c -v -Wl,--verbose &> log-8.26_long.out
readelf -l a.out | grep ': /lib' > log-8.26.out
rm -v a.out

echo "Check log-8.26.out and log-8.26_long.out"
echo
read -p "Press Y to contiue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf gcc-10.2.0


#-----
echo "# 8.27. Pkg-config-0.29.2"
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
echo "# 8.28. Ncurses-6.2"
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
echo "# 8.29. Sed-4.8"
tar -xf sed-4.8.tar.xz
cd sed-4.8

./configure --prefix=/usr --bindir=/bin 

make || exit 
make html || exit
make install || exit 1
install -d -m755           /usr/share/doc/sed-4.8
install -m644 doc/sed.html /usr/share/doc/sed-4.8

cd $LFS/sources
rm -rf sed-4.8

#-----
echo "# 8.30. Psmisc-23.3"
tar -xf psmisc-23.3.tar.xz
cd psmisc-23.3

./configure --prefix=/usr
make || exit 1
make install || exit 1
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

cd $LFS/sources
rm -rf psmisc-23.3

#-----
echo "# 8.31. Gettext-0.21"
tar -xf gettext-0.21.tar.xz
cd gettext-0.21

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.21

make || exit 1
make install || exit 1
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd $LFS/sources
rm -rf gettext-0.21

#-----
echo "# 8.32. Bison-3.7.1"
tar -xf bison-3.7.1.tar.xz
cd bison-3.7.1

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf bison-3.7.1

#-----
echo "# 8.33. Grep-3.4"
tar -xf grep-3.4.tar.xz
cd grep-3.4

./configure --prefix=/usr --bindir=/bin

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf grep-3.4

#-----
echo "# 8.34. Bash-5.0"
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
echo "# 8.35. Libtool-2.4.6"
tar -xf libtool-2.4.6.tar.xz
cd libtool-2.4.6

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf libtool-2.4.6

#-----
echo "# 8.36. GDBM-1.18.1"
tar -xf gdbm-1.18.1.tar.gz
cd gdbm-1.18.1

sed -r -i '/^char.*parseopt_program_(doc|args)/d' src/parseopt.c

./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf gdbm-1.18.1

#-----
echo "8.37. Gperf-3.1"
tar -xf gperf-3.1.tar.gz
cd gperf-3.1

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf gperf-3.1

#-----
echo "8.38. Expat-2.2.9"
tar -xf expat-2.2.9.tar.xz
cd expat-2.2.9

./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat-2.2.9

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf expat-2.2.9

#-----
echo "# 8.39. Inetutils-1.9.4"
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
echo "# 8.40. Perl-5.32.0"
tar -xf perl-5.32.0.tar.xz
cd perl-5.32.0

export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
		  -Dprivlib=/usr/lib/perl5/5.32/core_perl \
		  -Darchlib=/usr/lib/perl5/5.32/core_perl \
		  -Dsitelib=/usr/lib/perl5/5.32/site_perl \
		  -Dsitearch=/usr/lib/perl5/5.32/site_perl \
		  -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
		  -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib			\
		  -Dusethreads

make || exit 1
make install || exit 1
unset BUILD_ZLIB BUILD_BZIP2

cd $LFS/sources
rm -rf perl-5.32.0

#-----
echo "8.41. XML::Parser-2.46"
tar -xf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46

perl Makefile.PL
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf XML-Parser-2.46

#-----
echo "8.42. Intltool-0.51.0"
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr
make || exit 1
make install || exit 1
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd $LFS/sources
rm -rf intltool-0.51.0

#-----
echo "# 8.43. Autoconf-2.69"
tar -xf autoconf-2.69.tar.xz
cd autoconf-2.69

sed '361 s/{/\\{/' -i bin/autoscan.in

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf autoconf-2.69

#-----
echo "# 8.44. Automake-1.16.2"
tar -xf automake-1.16.2.tar.xz
cd automake-1.16.2

sed -i "s/''/etags/" t/tags-lisp-space.sh
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.2

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf automake-1.16.2

#-----
echo "# 8.45. Kmod-27"
tar -xf kmod-27.tar.xz
cd kmod-27

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
rm -rf kmod-27

#-----
echo "# 8.46 Libelf from Elfutils-0.180"
tar -xf elfutils-0.180.tar.bz2
cd elfutils-0.180

./configure --prefix=/usr --disable-debuginfod --libdir=/lib

make || exit 1
make -C libelf install || exit 1
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd $LFS/sources
rm -rf elfutils-0.180

#----
echo "# 8.47 Libffi-3.3"
tar -xf libffi-3.3.tar.gz
cd libffi-3.3

./configure --prefix=/usr --disable-static --with-gcc-arch=native

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf libffi-3.3

#-----
echo "# 8.48 OpenSSL-1.1.1g"
tar -xf openssl-1.1.1g.tar.gz
cd openssl-1.1.1g

./config --prefix=/usr \
	 --openssldir=/etc/ssl \
	 --libdir=lib \
	 shared \
	 zlib-dynamic

make || exit 1
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install || exit 1
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1g
cp -vfr doc/* /usr/share/doc/openssl-1.1.1g

cd $LFS/sources
rm -rf openssl-1.1.1g

#-----
echo "# 8,49 Python-3.8.5"
tar -xf Python-3.8.5.tar.xz
cd Python-3.8.5

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

install -v -dm755 /usr/share/doc/python-3.8.5/html
tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.8.5/html \
    -xvf ../python-3.8.5-docs-html.tar.bz2

cd $LFS/sources
rm -rf Python-3.8.5

#-----
echo "# 8.50 Ninja-1.10.0"
tar -xf ninja-1.10.0.tar.gz
cd ninja-1.10.0

python3 configure.py --bootstrap

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja

cd $LFS/sources
rm -rf ninja-1.10.0

#-----
echo "# 8.51 Meson-0.55.0"
tar -xf meson-0.55.0.tar.gz
cd meson-0.55.0

python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /

cd $LFS/sources
rm -rf meson-0.55.0

#-----
echo "# 8.52. Coreutils-8.32"
tar -xf coreutils-8.32.tar.xz
cd coreutils-8.32

patch -Np1 -i ../coreutils-8.32-i18n-1.patch 
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

cd $LFS/sources
rm -rf coreutils-8.32

#-----
echo "# 8.53 Check 0.15.2"
tar -xf check-0.15.2.tar.gz
cd check-0.15.2

./configure --prefix=/usr --disable-static

make || exit 1
make docdir=/usr/share/doc/check-0.15.2 install || exit 1

cd $LFS/sources
rm -rf check-0.15.2

#-----
echo "# 8.54. Diffutils-3.7"
tar -xf diffutils-3.7.tar.xz
cd diffutils-3.7

./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf diffutils-3.7

#-----
echo "# 8.55. Gawk-5.1.0"
tar -xf gawk-5.1.0.tar.xz
cd gawk-5.1.0

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf gawk-5.1.0

#-----
echo "# 8.56. Findutils-4.7.0"
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
echo "# 8.57. Groff-1.22.4"
tar -xf groff-1.22.4.tar.gz
cd groff-1.22.4

PAGE=letter ./configure --prefix=/usr
make -j1 || exit 1
make install || exit 1

cd $LFS/sources
rm -rf groff-1.22.4

#-----
echo "# 8.58. GRUB-2.04"
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
echo "# 8.59. Less-551"
tar -xf less-551.tar.gz
cd less-551

./configure --prefix=/usr --sysconfdir=/etc

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf less-551

#-----
echo "# 8.60. Gzip-1.10"
tar -xf gzip-1.10.tar.xz
cd gzip-1.10

./configure --prefix=/usr 

make || exit 1
make install || exit 1
mv -v /usr/bin/gzip /bin

cd $LFS/sources
rm -rf gzip-1.10

#-----
echo "# 8.61 IPRoute2-5.8.0"
tar -xf iproute2-5.8.0.tar.xz
cd iproute2-5.8.0

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
sed -i 's/.m_ipt.o//' tc/Makefile
make || exit 1
make DOCDIR=/usr/share/doc/iproute2-5.8.0 install || exit 1

cd $LFS/sources
rm -rf iproute2-5.8.0

#-----
echo "# 8.62. Kbd-2.3.0"
tar -xf kbd-2.3.0.tar.xz
cd kbd-2.3.0

patch -Np1 -i ../kbd-2.3.0-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock

make || exit 1
make install || exit 1
rm -v /usr/lib/libtswrap.{a,la,so*}
mkdir -v            /usr/share/doc/kbd-2.3.0
cp -R -v docs/doc/* /usr/share/doc/kbd-2.3.0

cd $LFS/sources
rm -rf kbd-2.3.0

#-----
echo "# 8.63. Libpipeline-1.5.3"
tar -xf libpipeline-1.5.3.tar.gz
cd libpipeline-1.5.3

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf libpipeline-1.5.3

#-----
echo "# 8.64. Make-4.3"
tar -xf make-4.3.tar.gz
cd make-4.3

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf make-4.3

#-----
echo "# 8.65. Patch-2.7.6"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/usr
make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf patch-2.7.6

#-----
echo "# 8.66. Man-DB-2.9.3"
tar -xf man-db-2.9.3.tar.xz
cd man-db-2.9.3

sed -i '/find/s@/usr@@' init/systemd/man-db.service.in
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.9.3 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
	    --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap

make || exit 1
make install || exit 1

cd $LFS/sources
rm -rf man-db-2.9.3

#-----
echo "# 8.67. Tar-1.32"
tar -xf tar-1.32.tar.xz
cd tar-1.32

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin

make || exit 1
make install || exit 1
make -C doc install-html docdir=/usr/share/doc/tar-1.32 || exit 1

cd $LFS/sources
rm -rf tar-1.32

#-----
echo "# 8.68. Texinfo-6.7"
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7

./configure --prefix=/usr --disable-static
make || exit 1
make install || exit 1
make TEXMF=/usr/share/texmf install-tex || exit 1

cd $LFS/sources
rm -rf texinfo-6.7

#-----
echo "# 8.69. Vim-8.2.1361"
tar -xf vim-8.2.1361.tar.gz
cd vim-8.2.1361

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr

make || exit 1
make install || exit 1

ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
   ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.1361

# 8.69.2 configuring vim
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
rm -rf vim-8.2.1361

#-----
echo "# 8.70. Systemd-246"
tar -xf systemd-246.tar.gz
cd systemd-246

ln -sf /bin/true /usr/bin/xsltproc
tar -xf ../systemd-man-pages-246.tar.xz
sed '177,$ d' -i src/resolve/meson.build
sed -i 's/GROUP="render", //' rules.d/50-udev-default.rules.in

mkdir -p build ; cd build
PKG_CONFIG_PATH="/usr/lib/pkgconfig" \
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
      -Dsplit-usr=true       \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false        \
      -Dumount-path=/bin/umount \
      -Db_lto=false           \
      -Drpmmacrosdir=no       \
      -Dhomed=false           \
      -Duserdb=false          \
      -Dman=true              \
      -Ddocdir=/usr/share/doc/systemd-246 \
      .. &> log.txt

LANG=en_US.UTF-8 ninja || exit 1
LANG=en_US.UTF-8 ninja install || exit 1
rm -f /usr/bin/xsltproc
systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-time-wait-sync.service
rm -f /usr/lib/sysctl.d/50-pid-max.conf

cd $LFS/sources
rm -rf systemd-246

#-----
echo "# 8.71. D-Bus-1.12.20"
tar -xf dbus-1.12.20.tar.gz
cd dbus-1.12.20

./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.12.20 \
            --with-console-auth-dir=/run/console

make || exit 1
make install || exit 1
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
ln -sfv /etc/machine-id /var/lib/dbus
sed -i 's:/var/run:/run:' /lib/systemd/system/dbus.socket

cd $LFS/sources
rm -rf dbus-1.12.20

#-----
echo "# 8.72. Procps-ng-3.3.16"
tar -xf procps-ng-3.3.16.tar.xz
cd procps-ng-3.3.16

./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.16 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd

make || exit 1
make install || exit 1
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

cd $LFS/sources
rm -rf procps-ng-3.3.16

#-----
echo "# 8.73. util-linux-2.36"
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

#-----
echo "# 8.74. E2fsprogs-1.45.6"
tar -xf e2fsprogs-1.45.6.tar.gz
cd e2fsprogs-1.45.6

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
rm -rf e2fsprogs-1.45.6


#-----
echo "Set root password:"
passwd root

echo "Continue to 8.76: Stripping Again"
echo 

echo ""
echo "=== End of Chapter 8 ==="
echo ""


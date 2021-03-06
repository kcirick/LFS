#!/bin/bash

timer() {
   if [ $# -eq 0 ]; then
      echo $(date '+%s')
   else
      local stime=$1
      etime=$(date '+%s')
      if [ -z "$stime" ]; then stime=$etime; fi
      dt=$((etime - stime))
      ds=$((dt % 60))
      dm=$(((dt / 60) % 60))
      dh=$((dt / 3600))
      printf '%02d:%02d:%02d' $dh $dm $ds
   fi
}

#-------------------------------------------------------------------------

if [ "$(whoami)" != "lfs" ] ; then
   echo "Not running as user lfs, you should be!"
   return;
fi

if [ -z $LFS ]; then
   echo "\$LFS not set! Exiting..."
   return;
fi

if [ $(stat -c %U $LFS/tools) != "lfs" ] ; then
   echo "$LFS/tools should be owned by user lfs!"
   return;
fi


cd $LFS/sources
echo 'int main(){}' > dummy.c

exit

#-----
sbu_time=$(timer)
echo "# 5.4. Binutils-2.26 - Pass 1"
tar -xf binutils-2.26.tar.bz2
cd binutils-2.26
mkdir -v build && cd build
../configure   \
   --prefix=/tools            \
   --with-sysroot=$LFS        \
   --with-lib-path=/tools/lib \
   --target=$LFS_TGT          \
   --disable-nls              \
   --disable-werror
make || exit 1
mkdir -v /tools/lib
ln -sv lib /tools/lib64
make install || exit 1
cd $LFS/sources
rm -rf binutils-2.26

echo "\n=========================="
printf 'Your SBU time is: %s\n' $(timer $sbu_time)
echo "==========================\n"

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi


#-----
echo "# 5.5. gcc-5.3.0 - Pass 1"
tar -xf gcc-5.3.0.tar.bz2
cd gcc-5.3.0

tar -Jxf ../mpfr-3.1.3.tar.xz
mv -v mpfr-3.1.3 mpfr
tar -Jxf ../gmp-6.1.0.tar.xz
mv -v gmp-6.1.0 gmp
tar -zxf ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

for file in \
   $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
   do
   cp -uv $file{,.orig}
   sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
       -e 's@/usr@/tools@g' $file.orig > $file
   echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
   touch $file.orig
done

mkdir -v build && cd build
../configure                                      \
   --target=$LFS_TGT                              \
   --prefix=/tools                                \
   --with-glibc-version=2.11                      \
   --with-sysroot=$LFS                            \
   --with-newlib                                  \
   --without-headers                              \
   --with-local-prefix=/tools                     \
   --with-native-system-header-dir=/tools/include \
   --disable-nls                                  \
   --disable-shared                               \
   --disable-multilib                             \
   --disable-decimal-float                        \
   --disable-threads                              \
   --disable-libatomic                            \
   --disable-libgomp                              \
   --disable-libquadmath                          \
   --disable-libssp                               \
   --disable-libvtv                               \
   --disable-libstdcxx                            \
   --enable-languages=c,c++

make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gcc-5.3.0

#-----
echo "# 5.6. Linux API Headers"
tar -xf linux-4.4.8.tar.xz
cd linux-4.4.8
make mrproper || exit 1
make INSTALL_HDR_PATH=dest headers_install || exit 1
cp -rv dest/include/* /tools/include
cd $LFS/sources
rm -rf linux-4.4.8

#-----
echo "# 5.7. Glibc-2.23"
tar -xf glibc-2.23.tar.xz
cd glibc-2.23
mkdir -v build && cd build
../configure                            \
   --prefix=/tools                      \
   --host=$LFS_TGT                      \
   --build=$(../scripts/config.guess) 	\
   --disable-profile                    \
   --enable-kernel=2.6.32               \
   --enable-obsolete-rpc                \
   --with-headers=/tools/include        \
   libc_cv_forced_unwind=yes            \
   libc_cv_ctors_header=yes             \
   libc_cv_c_cleanup=yes
make || exit 1
make install || exit 1

cd $LFS/sources

echo "Checking the compiler..."
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools' > log-5.7.out
rm -v a.out

echo "Check log-5.7.out. Does it say:"
echo "   [Requesting program interpreter: /tools/lib/ld-linux.so.2]"
echo

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi

rm -rf glibc-2.23

#-----
echo "# 5.8. Libstdc++-5.3.0"
tar -xf gcc-5.3.0.tar.bz2
cd gcc-5.3.0
mkdir -pv build && cd build
../libstdc++-v3/configure \
   --host=$LFS_TGT                 \
   --prefix=/tools                 \
   --disable-multilib              \
   --disable-nls                   \
   --disable-libstdcxx-threads     \
   --disable-libstdcxx-pch         \
   --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/5.3.0
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gcc-5.3.0

#-----
echo "# 5.9. Binutils-2.26 - Pass 2"
tar -xf binutils-2.26.tar.bz2
cd binutils-2.26
mkdir -v build && cd build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                  \
   --prefix=/tools            \
   --disable-nls              \
   --disable-werror           \
   --with-lib-path=/tools/lib \
   --with-sysroot
make || exit 1
make install || exit 1
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
cd $LFS/sources
rm -rf binutils-2.26

#-----
echo "# 5.10. gcc-5.3.0 - Pass 2"
tar -xf gcc-5.3.0.tar.bz2
cd gcc-5.3.0

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
   `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in \
   $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
   do
   cp -uv $file{,.orig}
   sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
       -e 's@/usr@/tools@g' $file.orig > $file
   echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
   touch $file.orig
done

tar -Jxf ../mpfr-3.1.3.tar.xz
mv -v mpfr-3.1.3 mpfr
tar -Jxf ../gmp-6.1.0.tar.xz
mv -v gmp-6.1.0 gmp
tar -zxf ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

mkdir -v build && cd build
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                      \
   --prefix=/tools                                \
   --with-local-prefix=/tools                     \
   --with-native-system-header-dir=/tools/include \
   --enable-languages=c,c++                       \
   --disable-libstdcxx-pch                        \
   --disable-multilib                             \
   --disable-bootstrap                            \
   --disable-libgomp

make || exit 1
make install || exit 1
ln -sv gcc /tools/bin/cc
cd $LFS/sources

echo "Checking the compiler..."
cc dummy.c
readelf -l a.out | grep ': /tools' > log-5.10.out
rm -v a.out

echo "Check log-5.10.out. Does it say:"
echo "   [Requesting program interpreter: /tools/lib/ld-linux.so.2]"
echo

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi

rm -rf gcc-5.3.0

#-----
# WARNING: MAY NOT BE NEEDED!
echo "# 5.11. Tcl-core-8.6.4"
echo "---> Skipping"
#tar -xf tcl-core8.6.4-src.tar.gz
#cd tcl8.6.4/unix
#./configure --prefix=/tools
#make || exit 1
#make install || exit 1
#chmod -v u+w /tools/lib/libtcl8.6.so
#make install-private-headers
#ln -sv tclsh8.6 /tools/bin/tclsh
#cd $LFS/sources
#rm -rf tcl8.6.4

#-----
# WARNING: MAY NOT BE NEEDED!
echo "# 5.12. Expect-5.45"
echo "---> Skipping"
#tar -xf expect5.45.tar.gz
#cd expect5.45
#cp -v configure configure.orig
#sed 's:/usr/local/bin:/bin:' configure.orig > configure
#./configure --prefix=/tools       \
#            --with-tcl=/tools/lib \
#            --with-tclinclude=/tools/include
#make || exit 1
#make SCRIPTS="" install || exit 1
#cd $LFS/sources
#rm -rf expect5.45

#-----
# WARNING: MAY NOT BE NEEDED!
echo "# 5.13. DejaGNU-1.5.3"
echo "---> Skipping"
#tar -xf dejagnu-1.5.3.tar.gz
#cd dejagnu-1.5.3
#./configure --prefix=/tools
#make install || exit 1
#cd $LFS/sources
#rm -rf dejagnu-1.5.3

#-----
# WARNING: MAY NOT BE NEEDED!
echo "# 5.14. Check-0.10.0"
echo "---> Skipping"
#tar -xf check-0.10.0.tar.gz
#cd check-0.10.0
#PKG_CONFIG= ./configure --prefix=/tools
#make || exit 1
#make install || exit 1
#cd $LFS/sources
#rm -rf check-0.10.0

#-----
echo "# 5.15. Ncurses-6.0"
tar -xf ncurses-6.0.tar.gz
cd ncurses-6.0
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf ncurses-6.0

#-----
echo "# 5.16. Bash-4.3.30"
tar -xf bash-4.3.30.tar.gz
cd bash-4.3.30
./configure --prefix=/tools --without-bash-malloc
make || exit 1
make install || exit 1
ln -sv bash /tools/bin/sh
cd $LFS/sources
rm -rf bash-4.3.30

#-----
echo "# 5.17. Bzip2-1.0.6"
tar -xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make || exit 1
make PREFIX=/tools install || exit 1
cd $LFS/sources
rm -rf bzip2-1.0.6

#-----
echo "# 5.18. Coreutils-8.25"
tar -xf coreutils-8.25.tar.xz
cd coreutils-8.25
./configure --prefix=/tools --enable-install-program=hostname
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf coreutils-8.25

#-----
echo "# 5.19. Diffutils-3.3"
tar -xf diffutils-3.3.tar.xz
cd diffutils-3.3
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf diffutils-3.3

#-----
echo "# 5.20. File-5.25"
tar -xf file-5.25.tar.gz
cd file-5.25
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf file-5.25

#-----
echo "# 5.21. Findutils-4.6.0"
tar -xf findutils-4.6.0.tar.gz
cd findutils-4.6.0
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf findutils-4.6.0

#-----
echo "# 5.22. Gawk-4.1.3"
tar -xf gawk-4.1.3.tar.xz
cd gawk-4.1.3
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gawk-4.1.3

#-----
echo "# 5.23. Gettext-0.19.7"
tar -xf gettext-0.19.7.tar.xz
cd gettext-0.19.7/gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib || exit 1
make -C intl pluralx.c || exit 1
make -C src msgfmt || exit 1
make -C src msgmerge || exit 1
make -C src xgettext || exit 1
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
cd $LFS/sources
rm -rf gettext-0.19.7

#-----
echo "# 5.24. Grep-2.23"
tar -xf grep-2.23.tar.xz
cd grep-2.23
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf grep-2.23

#-----
echo "# 5.25. Gzip-1.6"
tar -xf gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gzip-1.6

#-----
echo "# 5.26. M4-1.4.17"
tar -xf m4-1.4.17.tar.xz
cd m4-1.4.17
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf m4-1.4.17

#-----
echo "# 5.27. Make-4.1"
tar -xf make-4.1.tar.bz2
cd make-4.1
./configure --prefix=/tools --without-guile
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf make-4.1

#-----
echo "# 5.28. Patch-2.7.5"
tar -xf patch-2.7.5.tar.xz
cd patch-2.7.5
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf patch-2.7.5

#-----
echo "# 5.29. Perl-5.22.1"
tar -xf perl-5.22.1.tar.bz2
cd perl-5.22.1
sh Configure -des -Dprefix=/tools -Dlibs=-lm
make || exit 1
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.22.1
cp -Rv lib/* /tools/lib/perl5/5.22.1
cd $LFS/sources
rm -rf perl-5.22.1

#-----
echo "# 5.30. Sed-4.2.2"
tar -xf sed-4.2.2.tar.bz2
cd sed-4.2.2
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf sed-4.2.2

#-----
echo "# 5.31. Tar-1.28"
tar -xf tar-1.28.tar.xz
cd tar-1.28
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf tar-1.28

#-----
echo "# 5.32. Texinfo-6.1"
tar -xf texinfo-6.1.tar.xz
cd texinfo-6.1
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf texinfo-6.1

#-----
echo "# 5.33. Util-linux-2.27.1"
tar -xf util-linux-2.27.1.tar.xz
cd util-linux-2.27.1
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf util-linux-2.27.1

#-----
echo "# 5.34. Xz-5.2.2"
tar -xf xz-5.2.2.tar.xz
cd xz-5.2.2
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf xz-5.2.2

#-------------------------------------------------------------------------
echo "Stripping..."

strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*

rm -rf /tools/{,share}/{info,man,doc}

echo "Don't forget to do 5.36: Changing Ownership"
echo ""
echo "=== End of Chapter 5 ==="
echo ""

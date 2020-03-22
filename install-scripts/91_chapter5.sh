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

section=$1

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

#exit

echo "Section is $section"

if [ $section -eq 1 ]
then

cd $LFS/sources

#-----
sbu_time=$(timer)
echo "# 5.4. Binutils-2.34 - Pass 1"
tar -xf binutils-2.34.tar.xz
cd binutils-2.34
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
rm -rf binutils-2.34

echo "\n=========================="
printf 'Your SBU time is: %s\n' $(timer $sbu_time)
echo "==========================\n"

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi


#-----
echo "# 5.5. gcc-9.2.0 - Pass 1"
tar -xf gcc-9.2.0.tar.xz
cd gcc-9.2.0

tar -Jxf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -Jxf ../gmp-6.2.0.tar.xz
mv -v gmp-6.2.0 gmp
tar -zxf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

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

case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib' \
			-i.org gcc/config/i386/t-linux64
	;;
esac

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
rm -rf gcc-9.2.0

#-----
echo "# 5.6. Linux API Headers"
tar -xf linux-5.5.3.tar.xz
cd linux-5.5.3
make mrproper || exit 1
make headers || exit 1
cp -rv usr/include/* /tools/include
cd $LFS/sources
rm -rf linux-5.5.3

#-----
echo "# 5.7. Glibc-2.31"
tar -xf glibc-2.31.tar.xz
cd glibc-2.31
mkdir -v build && cd build
../configure                            \
   --prefix=/tools                      \
   --host=$LFS_TGT                      \
   --build=$(../scripts/config.guess) 	\
   --enable-kernel=3.2                  \
   --with-headers=/tools/include        \
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

rm -rf glibc-2.31

elif [ $section -eq 2 ] 
then

#-----
echo "# 5.8. Libstdc++-9.2.0"
tar -xf gcc-9.2.0.tar.xz
cd gcc-9.2.0
mkdir -pv build && cd build
../libstdc++-v3/configure \
   --host=$LFS_TGT                 \
   --prefix=/tools                 \
   --disable-multilib              \
   --disable-nls                   \
   --disable-libstdcxx-threads     \
   --disable-libstdcxx-pch         \
   --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/9.2.0
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gcc-9.2.0

#-----
echo "# 5.9. Binutils-2.34 - Pass 2"
tar -xf binutils-2.34.tar.xz
cd binutils-2.34
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
rm -rf binutils-2.34

#-----
echo "# 5.10. gcc-9.2.0 - Pass 2"
tar -xf gcc-9.2.0.tar.xz
cd gcc-9.2.0

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
   `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in \
   $(find gcc/config -name linux64.h -o -name linux.h)
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

case $(name -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/i386/t-linux64
	;;
esac

tar -Jxf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -Jxf ../gmp-6.2.0.tar.xz
mv -v gmp-6.2.0 gmp
tar -zxf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

sed -e '1161 s|^|//|' \
	-i libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

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

rm -rf gcc-9.2.0

elif [ $section -eq 3 ] 
then

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
echo "# 5.14. M4-1.4.18"
tar -xf m4-1.4.18.tar.xz
cd m4-1.4.18

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf m4-1.4.18

#-----
# WARNING: MAY NOT BE NEEDED!
#echo "# 5.14. Check-0.10.0"
#echo "---> Skipping"
#tar -xf check-0.10.0.tar.gz
#cd check-0.10.0
#PKG_CONFIG= ./configure --prefix=/tools
#make || exit 1
#make install || exit 1
#cd $LFS/sources
#rm -rf check-0.10.0

#-----
echo "# 5.15. Ncurses-6.2"
tar -xf ncurses-6.2.tar.gz
cd ncurses-6.2
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make || exit 1
make install || exit 1
ln -s libncursesw.so /tools/lib/libncurses.so
cd $LFS/sources
rm -rf ncurses-6.2

#-----
echo "# 5.16. Bash-5.0"
tar -xf bash-5.0.tar.gz
cd bash-5.0
./configure --prefix=/tools --without-bash-malloc
make || exit 1
make install || exit 1
ln -sv bash /tools/bin/sh
cd $LFS/sources
rm -rf bash-5.0

#-----
echo "# 5.17. Bison-3.5.2"
tar -xf bison-3.5.2.tar.xz
cd bison-3.5.2
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf bison-3.5.2

#-----
echo "# 5.18. Bzip2-1.0.8"
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
make -f Makefile-libbz2_so || exit 1
make clean
make || exit 1
make PREFIX=/tools install || exit 1
cp -v bzip2-shared /tools/bin/bzip2
cp -av libbz2.so* /tools/lib
ln -sv libbz2.so.1.0 /tools/lib/libbz2.so
cd $LFS/sources
rm -rf bzip2-1.0.8

#-----
echo "# 5.19. Coreutils-8.31"
tar -xf coreutils-8.31.tar.xz
cd coreutils-8.31
./configure --prefix=/tools --enable-install-program=hostname
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf coreutils-8.31

#-----
echo "# 5.20. Diffutils-3.7"
tar -xf diffutils-3.7.tar.xz
cd diffutils-3.7
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf diffutils-3.7

#-----
echo "# 5.21. File-5.38"
tar -xf file-5.38.tar.gz
cd file-5.38
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf file-5.38

#-----
echo "# 5.22. Findutils-4.7.0"
tar -xf findutils-4.7.0.tar.xz
cd findutils-4.7.0
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf findutils-4.7.0

#-----
echo "# 5.23. Gawk-5.0.1"
tar -xf gawk-5.0.1.tar.xz
cd gawk-5.0.1
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gawk-5.0.1

#-----
echo "# 5.24. Gettext-0.20.1"
tar -xf gettext-0.20.1.tar.xz
cd gettext-0.20.1
./configure --disable-shared
make || exit 1
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin
cd $LFS/sources
rm -rf gettext-0.20.1

#-----
echo "# 5.25. Grep-3.4"
tar -xf grep-3.4.tar.xz
cd grep-3.4
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf grep-3.4

#-----
echo "# 5.26. Gzip-1.10"
tar -xf gzip-1.10.tar.xz
cd gzip-1.10
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf gzip-1.10

#-----
echo "# 5.27. Make-4.3"
tar -xf make-4.3.tar.bz2
cd make-4.3
./configure --prefix=/tools --without-guile
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf make-4.3

#-----
echo "# 5.28. Patch-2.7.6"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf patch-2.7.6

#-----
echo "# 5.29. Perl-5.30.1"
tar -xf perl-5.30.1.tar.xz
cd perl-5.30.1
sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make || exit 1
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.30.1
cp -Rv lib/* /tools/lib/perl5/5.30.1
cd $LFS/sources
rm -rf perl-5.30.1

#-----
echo "# 5.30 Python-3.8.1"
tar -xf Python-3.8.1.tar.xz
cd Python-3.8.1
sed -i '/def add_multiarch_paths/a \		return' setup.py
./configure --prefix=/tools --without-ensurepip
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf Python-3.8.1

#-----
echo "# 5.31. Sed-4.8"
tar -xf sed-4.8.tar.xz
cd sed-4.8
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf sed-4.8

#-----
echo "# 5.32. Tar-1.32"
tar -xf tar-1.32.tar.xz
cd tar-1.32
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf tar-1.32

#-----
echo "# 5.33. Texinfo-6.7"
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf texinfo-6.7

#-----
echo "# 5.34. Util-linux-2.35.1"
tar -xf util-linux-2.35.1.tar.xz
cd util-linux-2.35.1
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
	    --without-ncurses              \
            PKG_CONFIG=""
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf util-linux-2.35.1

#-----
echo "# 5.35. Xz-5.2.4"
tar -xf xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/tools
make || exit 1
make install || exit 1
cd $LFS/sources
rm -rf xz-5.2.4

#-------------------------------------------------------------------------
echo "Stripping..."

strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*

rm -rf /tools/{,share}/{info,man,doc}

echo "Don't forget to do 5.37: Changing Ownership"
echo ""
echo "=== End of Chapter 5 ==="
echo ""


fi

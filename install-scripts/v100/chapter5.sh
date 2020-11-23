#!/bin/bash


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


#-----
echo "# 5.2. Binutils-2.35 - Pass 1"

tar -xf binutils-2.35.tar.xz
cd binutils-2.35

mkdir -v build && cd build
../configure --prefix=$LFS/tools        \
             --with-sysroot=$LFS        \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

make || exit 1
make install || exit 1

cd $LFS/sources
#rm -rf binutils-2.34


#-----
echo "# 5.3. gcc-10.2.0 - Pass 1"

tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0

tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.0.tar.xz
mv -v gmp-6.2.0 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.org gcc/config/i386/t-linux64
	;;
esac

mkdir -v build && cd build
../configure --target=$LFS_TGT                              \
             --prefix=$LFS/tools                            \
             --with-glibc-version=2.11                      \
             --with-sysroot=$LFS                            \
             --with-newlib                                  \
             --without-headers                              \
             --enable-initfini-array                        \
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

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

cd $LFS/sources
#rm -rf gcc-9.2.0


#-----
echo "# 5.4. Linux API Headers"
tar -xf linux-5.8.3.tar.xz
cd linux-5.8.3

make mrproper || exit 1
make headers || exit 1

find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $LFS/usr

cd $LFS/sources
#rm -rf linux-5.8.3


#-----
echo "# 5.5. Glibc-2.32"
tar -xf glibc-2.32.tar.xz
cd glibc-2.32

ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3

patch -Np1 -i $LFS/sources/glibc-2.32-fhs-1.patch

mkdir -v build && cd build
../configure --prefix=/usr                      \
             --host=$LFS_TGT                    \
             --build=$(../scripts/config.guess) \
             --enable-kernel=3.2                \
             --with-headers=$LFS/usr/include    \
	     libc_cv_slibdir=/lib

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources

echo "Checking the compiler..."
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep '/ld-linux' > log-5.5.out
rm -v a.out

echo "Check log-5.5.out. Does it say:"
echo "   [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
echo

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi


#rm -rf glibc-2.31

$LFS/tools/libexec/gcc/$LFS_TGT/10.2.0/install-tools/mkheaders

#-----
echo "# 5.6. Libstdc++ from gcc-10.2.0"
rm -rf gcc-10.2.0
tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0

mkdir -pv build && cd build
../libstdc++-v3/configure --host=$LFS_TGT                 \
                          --build=$(../config.guess)      \
			  --prefix=/usr                   \
                          --disable-multilib              \
                          --disable-nls                   \
                          --disable-libstdcxx-pch         \
                          --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/10.2.0

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
#rm -rf gcc-9.2.0

echo ""
echo "=== End of Chapter 5 ==="
echo ""


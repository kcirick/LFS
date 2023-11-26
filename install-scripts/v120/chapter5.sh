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
echo "# 5.2. Binutils-2.41 - Pass 1"

tar -xf binutils-2.41.tar.xz
cd binutils-2.41

mkdir -v build && cd build
../configure --prefix=$LFS/tools        \
             --with-sysroot=$LFS        \
             --target=$LFS_TGT          \
             --disable-nls              \
             --enable-gprofng=no        \
             --disable-werror

make || exit 1
make install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   exit
fi
rm -rf binutils-2.41


#-----
echo "# 5.3. gcc-13.2.0 - Pass 1"

tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0

tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/i386/t-linux64
	;;
esac

mkdir -v build && cd build
../configure --target=$LFS_TGT                              \
             --prefix=$LFS/tools                            \
             --with-glibc-version=2.38                      \
             --with-sysroot=$LFS                            \
             --with-newlib                                  \
             --without-headers                              \
             --enable-default-pie                           \
             --enable-default-ssp                           \
             --disable-nls                                  \
             --disable-shared                               \
             --disable-multilib                             \
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
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

cd $LFS/sources
# We still need this for 5.6
#rm -rf gcc-13.2.0


#-----
echo "# 5.4. Linux API Headers"
tar -xf linux-6.1.62.tar.xz
cd linux-6.1.62

make mrproper || exit 1
make headers || exit 1

find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

cd $LFS/sources
rm -rf linux-6.1.62


#-----
echo "# 5.5. Glibc-2.38"
tar -xf glibc-2.38.tar.xz
cd glibc-2.38


patch -Np1 -i $LFS/sources/glibc-2.38-fhs-1.patch

mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                      \
             --host=$LFS_TGT                    \
             --build=$(../scripts/config.guess) \
             --enable-kernel=4.14               \
             --with-headers=$LFS/usr/include    \
	     libc_cv_slibdir=/usr/lib

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources

echo "Checking the compiler..."
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep '/ld-linux' > log-5.5.out
rm -v a.out

echo "Check log-5.5.out. Does it say:"
echo "   [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
echo

read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi

#$LFS/tools/libexec/gcc/$LFS_TGT/10.2.0/install-tools/mkheaders

rm -rf glibc-2.38

#-----
echo "# 5.6. Libstdc++ from gcc-13.2.0"
#tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0

mkdir -pv build && cd build
../libstdc++-v3/configure --host=$LFS_TGT                 \
                          --build=$(../config.guess)      \
			                 --prefix=/usr                   \
                          --disable-multilib              \
                          --disable-nls                   \
                          --disable-libstdcxx-pch         \
                          --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0

make || exit 1
make DESTDIR=$LFS install || exit 1
rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la

cd $LFS/sources
rm -rf gcc-13.2.0

echo ""
echo "=== End of Chapter 5 ==="
echo ""


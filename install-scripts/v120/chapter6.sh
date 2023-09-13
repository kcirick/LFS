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

if [ $1 -eq 1 ]; then

#-----
echo "# 6.2. M4"
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19

./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf m4-1.4.19

#-----
echo "# 6.3. Ncurses"
tar -xf ncurses-6.4.tar.gz
cd ncurses-6.4

sed -i s/mawk// configure

mkdir build
pushd build
   ../configure
   make -C include
   make -C progs tic
popd

./configure --prefix=/usr   \
	         --host=$LFS_TGT \
	         --build=$(./config.guess) \
	         --mandir=/usr/share/man \
            --with-manpage-format=normal \
	         --with-shared   \
	         --without-normal \
            --with-cxx-shared \
            --without-debug \
            --without-ada   \
            --disable-stripping \
            --enable-widec

make || exit 1
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install || exit 1

echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf ncurses-6.4

#-----
echo "# 6.4. Bash"
tar -xf bash-5.2.15.tar.gz
cd bash-5.2.15

./configure --prefix=/usr              \
            --host=$LFS_TGT            \
            --build=$(sh support/config.guess) \
	         --without-bash-malloc

make || exit 1
make DESTDIR=$LFS install || exit 1

ln -sv bash $LFS/bin/sh

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf bash-5.2.15

#-----
echo "# 6.5. Coreutils"
tar -xf coreutils-9.3.tar.xz
cd coreutils-9.3

./configure --prefix=/usr               \
            --host=$LFS_TGT             \
            --build=$(build-aux/config.guess) \
	         --enable-install-program=hostname \
	         --enable-no-install-program=kill,uptime \
            gl_cv_macro_MB_CUR_MAX_good=y

make || exit 1
make DESTDIR=$LFS install || exit 1

mv -v $LFS/usr/bin/chroot                 $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1    $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                       $LFS/usr/share/man/man8/chroot.8

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf coreutils-9.3

#-----
echo "# 6.6. Diffutils"
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10

./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf diffutils-3.10

#-----
echo "# 6.7. File"
tar -xf file-5.45.tar.gz
cd file-5.45

mkdir build
pushd build
../configure --disable-bzlib \
             --disable-libseccomp \
             --disable-xzlib \
             --disable-zlib
make || exit 1
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/sec/file || exit 1
make DESTDIR=$LFS install || exit 1

rm -v $LFS/usr/lib/libmagic.la

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf file-5.45

#-----
echo "# 6.8. Findutils"
tar -xf findutils-4.9.0.tar.xz
cd findutils-4.9.0

./configure --prefix=/usr \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf findutils-4.9.0

#-----
echo "# 6.9. Gawk"
tar -xf gawk-5.2.2.tar.xz
cd gawk-5.2.2

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gawk-5.2.2

#-----
echo "# 6.10. Grep"
tar -xf grep-3.11.tar.xz
cd grep-3.11

./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf grep-3.11

#-----
echo "# 6.11. Gzip"
tar -xf gzip-1.12.tar.xz
cd gzip-1.12

./configure --prefix=/usr --host=$LFS_TGT

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gzip-1.12

#-----
echo "# 6.12. Make"
tar -xf make-4.4.1.tar.gz
cd make-4.4.1

./configure --prefix=/usr \
	    --host=$LFS_TGT \
	    --build=$(build-aux/config.guess) \
	    --without-guile

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf make-4.4.1

#-----
echo "# 6.13. Patch"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf patch-2.7.6

#-----
echo "# 6.14. Sed"
tar -xf sed-4.9.tar.xz
cd sed-4.9

./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf sed-4.9

#-----
echo "# 6.15. Tar"
tar -xf tar-1.35.tar.xz
cd tar-1.35

./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf tar-1.35

#-----
echo "# 6.16. Xz"
tar -xf xz-5.4.4.tar.xz
cd xz-5.4.4

./configure --prefix=/usr            \
	         --host=$LFS_TGT          \
	         --build=$(build-aux/config.guess) \
	         --disable-static         \
	         --docdir=/usr/share/doc/xz-5.4.4

make || exit 1
make DESTDIR=$LFS install || exit 1

rm -v $LFS/usr/lib/liblzma.la

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf xz-5.4.4

#-----
echo "# 6.17. Binutils - Pass 2"
tar -xf binutils-2.41.tar.xz
cd binutils-2.41

sed '6009s/$add_dir//' -i ltmain.sh

mkdir -v build && cd build
../configure --prefix=/usr            \
	          --host=$LFS_TGT          \
	          --build=$(../config.guess) \
             --disable-nls              \
             --disable-shared           \
             --enable-gprofng=no  \
	          --disable-werror           \
	          --enable-64-bit-bfd

make || exit 1
make DESTDIR=$LFS install || exit 1
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf binutils-2.41

fi

#-----
echo "# 6.18. gcc - Pass 2"
tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0

tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
   -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build
../configure --prefix=/usr                           \
	     --build=$(../config.guess)                   \
	     --host=$LFS_TGT                              \
        --target=$LFS_TGT                            \
        LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc    \
	     --with-build-sysroot=$LFS                    \
        --enable-default-pie                         \
        --enable-default-ssp                         \
	     --disable-nls                                \
	     --disable-multilib                           \
	     --disable-libatomic                          \
	     --disable-libgomp                            \
	     --disable-libquadmath                        \
        --disable-libsanitizer                       \
	     --disable-libssp                             \
        --disable-libvtv                             \
        --enable-languages=c,c++ 

make || exit 1
make DESTDIR=$LFS install || exit 1

ln -sv gcc $LFS/usr/bin/cc

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gcc-13.2.0


echo ""
echo "=== End of Chapter 6 ==="
echo ""


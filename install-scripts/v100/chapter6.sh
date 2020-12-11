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
echo "# 6.2. M4-1.4.18"
tar -xf m4-1.4.18.tar.xz
cd m4-1.4.18

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf m4-1.4.18

#-----
echo "# 6.3. Ncurses-6.2"
tar -xf ncurses-6.2.tar.gz
cd ncurses-6.2

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
            --without-debug \
            --without-ada   \
	    --without-normal \
            --enable-widec

make || exit 1
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install || exit 1

echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
mv -v $LFS/usr/lib/libncursesw.so.6* $LFS/lib
ln -sfv ../../lib/$(readlink $LFS/usr/lib/libncursesw.so) $LFS/usr/lib/libncursesw.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf ncurses-6.2

#-----
echo "# 6.4. Bash-5.0"
tar -xf bash-5.0.tar.gz
cd bash-5.0

./configure --prefix=/usr              \
            --host=$LFS_TGT            \
            --build=$(support/config.guess) \
	    --without-bash-malloc

make || exit 1
make DESTDIR=$LFS install || exit 1

mv $LFS/usr/bin/bash $LFS/bin/bash
ln -sv bash $LFS/bin/sh

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf bash-5.0

#-----
echo "# 6.5. Coreutils-8.32"
tar -xf coreutils-8.32.tar.xz
cd coreutils-8.32

./configure --prefix=/usr               \
            --host=$LFS_TGT             \
            --build=$(build-aux/config.guess) \
	    --enable-install-program=hostname \
	    --enable-no-install-program=kill,uptime

make || exit 1
make DESTDIR=$LFS install || exit 1

mv -v $LFS/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $LFS/bin
mv -v $LFS/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm}        $LFS/bin
mv -v $LFS/usr/bin/{rmdir,stty,sync,true,uname}               $LFS/bin
mv -v $LFS/usr/bin/{head,nice,sleep,touch}                    $LFS/bin
mv -v $LFS/usr/bin/chroot                                     $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1                        $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                                           $LFS/usr/share/man/man8/chroot.8

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf coreutils-8.32

#-----
echo "# 6.6. Diffutils-3.7"
tar -xf diffutils-3.7.tar.xz
cd diffutils-3.7

./configure --prefix=/usr --host=$LFS_TGT

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf diffutils-3.7

#-----
echo "# 6.7. File-5.39"
tar -xf file-5.39.tar.gz
cd file-5.39

./configure --prefix=/usr --host=$LFS_TGT

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf file-5.39

#-----
echo "# 6.8. Findutils-4.7.0"
tar -xf findutils-4.7.0.tar.xz
cd findutils-4.7.0

./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

mv -v $LFS/usr/bin/find $LFS/bin
sed -i 's|find:=${BINDIR}|find:=/bin|' $LFS/usr/bin/updatedb

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf findutils-4.7.0

#-----
echo "# 6.9. Gawk-5.1.0"
tar -xf gawk-5.1.0.tar.xz
cd gawk-5.1.0

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gawk-5.1.0

#-----
echo "# 6.10. Grep-3.4"
tar -xf grep-3.4.tar.xz
cd grep-3.4

./configure --prefix=/usr --host=$LFS_TGT --bindir=/bin

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf grep-3.4

#-----
echo "# 6.11. Gzip-1.10"
tar -xf gzip-1.10.tar.xz
cd gzip-1.10

./configure --prefix=/usr --host=$LFS_TGT

make || exit 1
make DESTDIR=$LFS install || exit 1
mv -v $LFS/usr/bin/gzip $LFS/bin

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gzip-1.10

#-----
echo "# 6.12. Make-4.3"
tar -xf make-4.3.tar.gz
cd make-4.3

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
rm -rf make-4.3

#-----
echo "# 6.13. Patch-2.7.6"
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf patch-2.7.6

#-----
echo "# 6.14. Sed-4.8"
tar -xf sed-4.8.tar.xz
cd sed-4.8

./configure --prefix=/usr --host=$LFS_TGT --bindir=/bin

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf sed-4.8

#-----
echo "# 6.15. Tar-1.32"
tar -xf tar-1.32.tar.xz
cd tar-1.32

./configure --prefix=/usr    \
	    --host=$LFS_TGT  \
	    --build=$(build-aux/config.guess) \
	    --bindir=/bin

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf tar-1.32

#-----
echo "# 6.16. Xz-5.2.5"
tar -xf xz-5.2.5.tar.xz
cd xz-5.2.5

./configure --prefix=/usr            \
	    --host=$LFS_TGT          \
	    --build=$(build-aux/config.guess) \
	    --disable-static         \
	    --docdir=/usr/share/doc/xz-5.2.5

make || exit 1
make DESTDIR=$LFS install || exit 1

mv -v $LFS/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat}  $LFS/bin
mv -v $LFS/usr/lib/liblzma.so.*                       $LFS/lib
ln -sfv ../../lib/$(readlink $LFS/usr/lib/liblzma.so) $LFS/usr/lib/liblzma.so

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf xz-5.2.5

#-----
echo "# 6.17. Binutils-2.35 - Pass 2"
tar -xf binutils-2.35.tar.xz
cd binutils-2.35

mkdir -v build && cd build
../configure --prefix=/usr            \
	     --host=$LFS_TGT          \
	     --build=$(../config.guess) \
             --disable-nls              \
             --disable-shared           \
	     --disable-werror           \
	     --enable-64-bit-bfd

make || exit 1
make DESTDIR=$LFS install || exit 1

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf binutils-2.35

fi

#-----
echo "# 6.18. gcc-10.2.0 - Pass 2"
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
			-i.orig gcc/config/i386/t-linux64
	;;
esac

mkdir -v build && cd build
mkdir -pv $LFS_TGT/libgcc
ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h

../configure --prefix=/usr                                \
	     --host=$LFS_TGT                              \
	     --build=$(../config.guess)                   \
	     CC_FOR_TARGET=$LFS_TGT-gcc                   \
	     --with-build-sysroot=$LFS                    \
	     --enable-initfini-array                      \
	     --disable-nls                                \
	     --disable-multilib                           \
	     --disable-decimal-float                      \
	     --disable-libatomic                          \
	     --disable-libgomp                            \
	     --disable-libquadmath                        \
	     --disable-libssp                             \
             --disable-libvtv                             \
	     --disable-libstdcxx                          \
             --enable-languages=c,c++ 

make || exit 1
make DESTDIR=$LFS install || exit 1

ln -sv gcc $LFS/usr/bin/cc

cd $LFS/sources
read -p "Press Y to continue: " answer
if [ "$answer" != "Y" ]; then
   return
fi
rm -rf gcc-10.2.0


echo ""
echo "=== End of Chapter 6 ==="
echo ""


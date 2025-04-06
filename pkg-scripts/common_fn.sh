#!/bin/bash

CWD=$(pwd)
TMPDIR=/var/pfs/build
TARGETDIR=/var/pfs/packages

SUDO=''
if [ -x /usr/bin/sudo -a $EUID != 0 ]; then SUDO='sudo'; fi

parse_args() {
   for i in "$@"; do
      case $i in 
         --download-only)
            DONLY=true
            shift
            ;;
         --no-wipe)
            NOWIPE=true
            shift
            ;;
         *)
            ;;
      esac
   done
}

check_deps() {
   for dep in ${DEP[@]}; do
      #echo $dep
      count=`ls -1 /var/pfs/log/installed_packages | egrep "^$dep-[0-9]" | wc -l`
      if [ ! "$count" -eq 1 ]; then
         echo ">>> WARNING!: Dependency package $dep doesn't seem to be installed!"
         read -p "Continue? [y/N]: " ans
         if [ "$ans" == "y" -o "$ans" == "Y" ]; then
            continue
         else
            exit 1
         fi
      fi
   done
}

do_download() {
   local FILENAME=$1
   local FILEURL=$2

   if [ ! -s $FILENAME ]; then wget $FILEURL$FILENAME; fi
}

do_download_list() {
   local ntotal=$(cat list.txt | wc -l)
   local nfiles=$(ls -1 *.tar.xz | wc -l)
   if [ ! $nfiles -eq $ntotal ]; then 
      echo "Fetching missing files..."
      wget --input-file=$SOURCELIST --continue
   fi
   nfiles=$(ls -1 *.tar.xz | wc -l)
   if [ ! $nfiles -eq $ntotal ]; then
      echo "ERROR: couldn't get all necessary files. Please try again"
      exit 1
   fi
}

apply_patch() {
   if [ ! "$NOWIPE" = true ]; then
      patch -Np1 -i $CWD/$PATCH || exit 1;
   fi
}

init_dirs() {
   PKGNAME=${TARGET}-${VERSION}_package
   PKGDIR=$TMPDIR/${PKGNAME}
   
   # init package directory
   $SUDO rm -rf $PKGDIR
   $SUDO mkdir -p $PKGDIR
   $SUDO chown -R root:root $PKGDIR

   # init build directory
   if [ ! "$NOWIPE" = true -a -z $SOURCELIST ]; then
      rm -rf $TMPDIR/$SOURCEDIR
      if [ "${SOURCE: -4}" == ".zip" ]; then
         unzip $CWD/$SOURCE -d $TMPDIR || exit 1
      else
         tar -xf $CWD/$SOURCE -C $TMPDIR || exit 1
      fi
   fi
}

make_package() {
   $SUDO find $PKGDIR | xargs file | grep -e "executable" -e "shared object" | grep ELF \
      | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null || true

   $SUDO mkdir -p $PKGDIR/install
   $SUDO cp -v $CWD/post_installation.sh $PKGDIR/install/

   cd $TMPDIR
   echo "$TARGETDIR/$PKGNAME.tar.xz"

   $SUDO mkdir -p $TARGETDIR
   $SUDO tar -Jcf $TARGETDIR/${PKGNAME}.tar.xz ${PKGNAME}
}

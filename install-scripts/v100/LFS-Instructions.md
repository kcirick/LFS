# Installation Instructions

 -  Version: 10.0-Systemd [Link](http://www.linuxfromscratch.org/lfs/view/stable-systemd/)
 -  Host: Debian Live LXDE 10
   - Additional software needed: git, bison, gawk, m4, texinfo, vim, parted

## Table of Contents
1. [Chapter 2](#chapter2)
2. [Chapter 3](#chapter3)
3. [Chapter 4](#chapter4)
4. [Chapter 5](#chapter5)
5. [Chapter 6](#chapter6)
6. [Chapter 7](#chapter7)
7. [Chapter 8](#chapter8)
8. [Chapter 9](#chapter9)
9. [End and BLFS](#end-blfs)


-----
<a name="chapter2" />

## Chapter 2 

### 2.4 Creating a New Partition

Use parted to partition the hard drive. eg:
 

	/dev/sda1     ext2     /boot    1   GiB
	    /sda2     ext4     /        200 GiB
	    /sda3     ext4     /home    250 GiB
       /sda4     swap              30 GiB

To format the partition:

    mkfs -v -t ext4 /dev/<xxx>

For swap partition:

    mkswap /dev/<yyy>


### 2.6/2.7 Setting the $LFS Variable

    export LFS=/mnt/lfs
    sudo mkdir $LFS
    sudo mount /dev/sda2 $LFS

If we are mounting directories on separate partitions, mount them:

    sudo mkdir $LFS/boot
    sudo mount -t ext2 /dev/sda1 $LFS/boot
    sudo mkdir $LFS/home
    sudo mount -t ext4 /dev/sda3 $LFS/home

mount swap partition:

    /sbin/swapon -v /dev/<zzz>


-----
<a name="chapter3" />

## Chapter 3

Create the source directory

    sudo mkdir $LFS/sources
    sudo chmod a+wt $LFS/sources

Download the packages and patches

    wget --input-file=list100_files.txt \
         --continue \
         --directory-prefix=$LFS/sources
    wget --input-file=list100_patches.txt \
         --continue \
         --directory-prefix=$LFS/sources

-----
<a name="chapter4" />

## Chapter 4

### 4.2 Creating the $LFS Directory Layout

     sudo mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var,tools}
     case $(uname -m) in
        x86_64) sudo mkdir -pv $LFS/lib64 ;;
     esac
  

### 4.3 Adding the LFS User

     sudo groupadd lfs
     sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
     sudo passwd lfs

Enter the password when prompted.

Next change the ownership of the folders

    sudo chown -v lfs $LFS/{usr,lib,var,etc,bin,sbin,tools,sources}
    case $(uname -m) in
       x86_64) sudo chown -v lfs $LFS/lib64 ;;
    esac

Then switch to the *lfs* user:

    su - lfs

### 4.4 Setting Up the Environment

Create ~/.bash_profile:

    cat > ~/.bash_profile << "EOF"
    exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
    EOF

and ~/.bashrc:

    cat > ~/.bashrc << "EOF"
    set +h
    umask 022
    LFS=/mnt/lfs
    LC_ALL=POSIX
    LFS_TGT=$(uname -m)-lfs-linux-gnu
    PATH=$LFS/tools/bin:$PATH
    export LFS LC_ALL LFS_TGT PATH
    EOF

Then load the profile:

    source ~/.bash_profile


-----
<a name="chapter5" />

## Chapter 5

 -  Follow 100-chapter5.sh
   - Perform tests at the end of 5.5

-----
<a name="chapter6" />

## Chapter 6

 -  Follow 100-chapter6.sh
   - 

-----
<a name="chapter7" />

## Chapter 7

 -  Follow 100-chapter7.sh
   -

-----
<a name="chapter8" />

## Chapter 8

### 6.2 Preparing Virtual Kernel File Systems

    sudo mkdir -pv $LFS/{dev,proc,sys,run}
    sudo mknod -m 600 $LFS/dev/console c 5 1
    sudo mknod -m 666 $LFS/dev/null c 1 3

Now mount system:

    sudo mount -v --bind /dev $LFS/dev
    sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
    sudo mount -vt proc proc $LFS/proc
    sudo mount -vt sysfs sysfs $LFS/sys
    sudo mount -vt tmpfs tmpfs $LFS/run

### 6.3 Package Management

Think about using pfstool for LFS. Currently used only for BLFS.

### 6.4 Entering the Chroot Environment

    chroot "$LFS" /tools/bin/env -i \
        HOME=/root                  \
        TERM="$TERM"                \
        PS1='\u:\w\$ '              \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
        /tools/bin/bash --login +h

It will say "I have no name!" in bash prompt.


### 6.5 and 6.6

 -  follow 79-chapter6-setup.sh
 -  Use above chroot command to re-login after the end of the script

### 6.7 to 6.78

 -  follow 79-chapter6.sh
   - Perform tests after 6.10 and 6.25
 -  Create root password

 -  Run 'logout' to log out before proceeding to section 6.79

### 6.79 Stripping Again

Re-enter the chroot environment:

    chroot $LFS /tools/bin/env -i            \
        HOME=/root TERM=$TERM PS1='\u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
        /tools/bin/bash --login

Then strip:
    
    save_lib="ld-2.31.so libc-2.31.so libpthread-2.31.so libthread_db-1.0.so"
    
    cd /lib
    
    for LIB in $save_lib; do
        objcopy --only-keep-debug $LIB $LIB.dbg
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB
    done

    save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.27
                 libitm.so.1.0.0 libatomic.so.1.2.0"

    cd /usr/lib

    for LIB in $save_usrlib; do
        objcopy --only-keep-debug $LIB $LIB.dbg
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB
    done

    unset LIB save_lib save_usrlib


    /tools/bin/find /usr/lib -type f -name \*.a \
	-exec /tools/bin/strip --strip-debug {} ';'

    /tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
	-exec /tools/bin/strip --strip-unneeded {} ';'

    /tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
	-exec /tools/bin/strip --strip-all {} ';'


### 6.72 Cleaning up

    rm -rf /tmp/*
    rm -f /usr/lib/lib{bfd,opcodes}.a
    rm -f /usr/lib/libbz2.a
    rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
    rm -f /usr/lib/libltdl.a
    rm -f /usr/lib/libfl.a
    rm -f /usr/lib/libz.a

    find /usr/lib /usr/libexec -name \*.la -delete


-----
<a name="chapter7" />
## Chapter 7

### 7.2 Network Configuration

For my purpose it will be DHCP configuration

    cat > /etc/systemd/network/10-wlp2s0-dhcp.network << "EOF"
    [Match]
    Name=wlp2s0

    [Network]
    DHCP=yes
    IPv6AcceptRouterAdvertisements=0
    EOF

Configure the hostname and /etc/hosts file

    echo "my_hostname" > /etc/hostname

    cat > /etc/hosts << "EOF"
    127.0.0.1 localhost my_hostname
    ::1       localhost
    EOF

### 7.8 Creating the /etc/inputrc File

    cat > /etc/inputrc << "EOF"
    # Begin /etc/inputrc
    # Modified by Chris Lynn <roryo@roryo.dynup.net>

    # Allow the command prompt to wrap to the next line
    set horizontal-scroll-mode Off

    # Enable 8bit input
    set meta-flag On
    set input-meta On

    # Turns off 8th bit stripping
    set convert-meta Off

    # Keep the 8th bit for display
    set output-meta On

    # none, visible or audible
    set bell-style none

    # All of the following map the escape sequence of the value
    # contained in the 1st argument to the readline specific functions
    "\eOd": backward-word
    "\eOc": forward-word

    # for linux console
    "\e[1~": beginning-of-line
    "\e[4~": end-of-line
    "\e[5~": beginning-of-history
    "\e[6~": end-of-history
    "\e[3~": delete-char
    "\e[2~": quoted-insert

    # for xterm
    "\eOH": beginning-of-line
    "\eOF": end-of-line

    # for Konsole
    "\e[H": beginning-of-line
    "\e[F": end-of-line

    # End /etc/inputrc
    EOF

### 7.9 Creating the /etc/shells file

    cat > /etc/shells << "EOF"
    # Begin /etc/shells

    /bin/sh
    /bin/bash

    # End /etc/shells
    EOF


-----
<a name="chapter8" />
## Chapter 8

### 8.2 Creating the /etc/fstab file

An example is given below. Customize for the specific system requirement

    cat > /etc/fstab << "EOF"
    /dev/sda1 /boot        ext2     defaults            0     0
    /dev/sda2 /home        ext4     defaults            0     1
    /dev/sda3 /            ext4     defaults,noatime    0     1    
    EOF

### 8.3 Building the kernel

 1. Prepare the compilation:

        make mrproper
        make defconfig

 2. Configure the kernel via ncurses UI

        make LANG=en_CA.UTF-8 menuconfig

 3. Compile the kernel image and modules
        
        make

 4. Install the modules

        make modules_install

 5. Copy the kernel image, System.map and configuration file to /boot

        cp -v arch/x86/boot/bzImage /boot/mvlinux-4.4.8-lfs
        cp -v System.map /boot/System.map-4.4.8
        cp -v .config /boot/config-4.4.8

### 8.4 GRUB boot loader

 1. Install grub:

        grub-install /dev/sda

 2. Write the GRUB configuration file

        cat > /boot/grub/grub.cfg << "EOF"
        # Begin /boot/grub/grub.cfg
        set default=0
        set timeout=5

        insmod ext2
        set root=(hd0,1)

        menuentry "LFS 7.9-systemd - 4.4.8" {
                linux   /vmlinuz-4.4.8-lfs root=/dev/sda3 ro
        }
        EOF

-----
<a name="chapter9" />
## Chapter 9

### 9.1

Create /etc/os-release file

    cat > /etc/os-release << "EOF"
    NAME="Linux From Scratch"
    VERSION="7.9-systemd"
    ID=lfs
    PRETTY_NAME="Linux From Scratch 7.9-systemd"
    EOF    

Create /etc/lfs-release

    echo 7.9-systemd > /etc/lfs-release

Create /etc/lsb-release (optional)

    cat > /etc/lsb-release << "EOF"
    DISTRIB_ID="Linux From Scratch"
    DISTRIB_RELEASE="7.9-systemd"
    DISTRIB_CODENAME="valkyrie"
    DISTRIB_DESCRIPTION="Linux From Scratch"
    EOF

### 9.3 Rebooting the system

First logout from the chroot environment:

    logout

Then unmount whatever is mounted:

    unmount -v $LFS/dev/pts
    unmount -v $LFS/dev
    unmount -v $LFS/run
    unmount -v $LFS/proc
    unmount -v $LFS/sys
    
    unmount -v $LFS/home
    unmount -v $LFS/boot
    
    unmount -v $LFS

Then finally reboot:

    shutdown -r now


-----
<a name="end-blfs" />
## End and BLFS

### Packages to install before anything else:

 1.  Bash shell scripts [[link](http://www.linuxfromscratch.org/blfs/view/systemd/postlfs/profile.html)]
 2.  lfs, pfstools (package manager)
 3.  wireless-tools, wpa_supplicant, wget



# Installation Instructions

 -  Version: 12.0-Systemd [Link](https://www.linuxfromscratch.org/lfs/view/12.0-systemd/)
 - System: Raspberry Pi 3
    - Quad Core 1.2GHz Broadcom BCM2837 64bit CPU (armv7)
    - 1024MB SDRAM
    - HDMI port
    - four USB 2.0 ports
    - Bluetooth 4.2, Bluetooth Low Energy (BLE), onboard antenna
    - CSI-2 camera connector 
 -  Host: Raspbian Bullseye armhf 
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
9. [Chapter 10](#chapter10)
10. [Chapter 11](#chapter11)
11. [End and BLFS](#end-blfs)


-----
<a name="chapter2" />

## Chapter 2 

### 2.4 Creating a New Partition

Use parted to partition the hard drive. eg:
 

	/dev/sdb1     ext2     /boot    512 MiB
       /sdb2     ext4     /         28 GiB

To format the partition:

    mkfs -v -t ext4 /dev/<xxx>


There is no need to create a dedicated swap partition! A swap file can be added at any time later on and is more flexible while offering the same performance

### 2.6/2.7 Setting the $LFS Variable

    export LFS=/mnt/lfs
    sudo mkdir $LFS
    sudo mount /dev/sda2 $LFS

If we are mounting directories on separate partitions, mount them:

    sudo mkdir $LFS/boot
    sudo mount -t ext2 /dev/sda1 $LFS/boot


-----
<a name="chapter3" />

## Chapter 3

Create the source directory

    sudo mkdir $LFS/sources
    sudo chmod a+wt $LFS/sources

Download the packages and patches

    wget --input-file=list120_files.txt \
         --continue \
         --directory-prefix=$LFS/sources
    wget --input-file=list120_patches.txt \
         --continue \
         --directory-prefix=$LFS/sources

-----
<a name="chapter4" />

## Chapter 4

### 4.2 Creating the $LFS Directory Layout

     sudo mkdir -pv $LFS/{etc,var,tools} $LFS/usr/{bin,lib,sbin}

     for i in bin lib sbin; do
         sudo ln -sv usr/$i $LFS/$i
     done

### 4.3 Adding the LFS User

     sudo groupadd lfs
     sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
     sudo passwd lfs

Enter the password when prompted.

Next change the ownership of the folders

    sudo chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,sources}


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
    LFS_TGT=$(uname -m)-lfs-linux-gnueabihf
    PATH=/usr/bin
    if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
    PATH=$LFS/tools/bin:$PATH
    CONFIG_SITE=$LFS/usr/share/config.site
    export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
    EOF

Then load the profile:

    source ~/.bash_profile


-----
<a name="chapter5" />

## Chapter 5

 -  Follow chapter5.sh
   - Perform tests at the end of 5.5

-----
<a name="chapter6" />

## Chapter 6

 -  Follow 100-chapter6.sh

-----
<a name="chapter7" />

## Chapter 7

  - Make sure to log out of lfs user, and that $LFS is set

### 7.2 Changing Ownership

    sudo chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
    case $(uname -m) in
       x86_64) sudo chown -R root:root $LFS/lib64 ;;
    esac

### 7.3 Preparing Virtual Kernel File Systems

    sudo mkdir -pv $LFS/{dev,proc,sys,run}
    sudo mknod -m 600 $LFS/dev/console c 5 1
    sudo mknod -m 666 $LFS/dev/null c 1 3

Now mount system:

    sudo mount -v --bind /dev $LFS/dev
    sudo mount -v --bind /dev/pts $LFS/dev/pts
    sudo mount -vt proc proc $LFS/proc
    sudo mount -vt sysfs sysfs $LFS/sys
    sudo mount -vt tmpfs tmpfs $LFS/run

    if [ -h $LFS/dev/shm ]; then
       sudo mkdir -pv $LFS/$(readlink $LFS/dev/shm)
    fi

### 7.4 Entering the Chroot Environment

    sudo chroot "$LFS" /tools/bin/env -i \
        HOME=/root                  \
        TERM="$TERM"                \
        PS1='(chroot) \u:\w\$ '              \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin \
        /bin/bash --login +h

It will say "I have no name!" in bash prompt.

### 7.5 and 7.6
 -  Follow 100-chapter7-setup.sh

### 7.7 to 7.13

 -  Follow 100-chapter7.sh

### 7.14 Cleaning up and Saving the Temporary System

Delete unneeded files and documents:

    find /usr/{lib,libexec} -name \*.la -delete
    rm -rf /usr/share/{info,man,doc}/*
    exit

Following are done outside of the chroot environment:

    sudo umount $LFS/dev{/pts,}
    sudo umount $LFS/{sys,proc,run}

Strip off debugging symbols:

     strip --strip-debug $LFS/usr/lib/*
     strip --strip-unneeded $LFS/usr/{,s}bin/*
     strip --strip-unneeded $LFS/tools/bin/*

Create a back up file

     cd $LFS &&
     tar -cJpf $HOME/lfs-temp-tools-10.0-systemd.tar.xz .

If a restore is needed:

     cd $LFS &&
     rm -rf ./* &&
     tar -xpf $HOME/lfs-temp-tools-10.0-systemd.tar.xz


-----
<a name="chapter8" />

## Chapter 8

**Make sure the virtual kernel file system is setup and under chroot environment before continuing!** 

### 8.2 Package Management

Think about using pfstool for LFS. Currently used only for BLFS.


### 8.3 to 8.74

 -  follow chapter8.sh
   - Perform tests after 8.26
 -  Create root password

 -  Run 'logout' to log out before proceeding to section 8.76

### 8.76 Stripping Again

Re-enter the chroot environment:

    chroot $LFS /usr/bin/env -i            \
        HOME=/root TERM=$TERM PS1='(chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
        /tools/bin/bash --login

Then strip:
    
    save_lib="ld-2.32.so libc-2.32.so libpthread-2.32.so libthread_db-1.0.so"
    
    cd /lib
    
    for LIB in $save_lib; do
        objcopy --only-keep-debug $LIB $LIB.dbg
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB
    done

    save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.28
                 libitm.so.1.0.0 libatomic.so.1.2.0"

    cd /usr/lib

    for LIB in $save_usrlib; do
        objcopy --only-keep-debug $LIB $LIB.dbg
        strip --strip-unneeded $LIB
        objcopy --add-gnu-debuglink=$LIB.dbg $LIB
    done

    unset LIB save_lib save_usrlib


    find /usr/lib -type f -name \*.a \
	-exec /tools/bin/strip --strip-debug {} ';'

    find /lib /usr/lib -type f -name \*.so* ! -name \*dbg \
	-exec /tools/bin/strip --strip-unneeded {} ';'

    find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
	-exec /tools/bin/strip --strip-all {} ';'


### 8.77 Cleaning up

    rm -rf /tmp/*

    rm -f /usr/lib/lib{bfd,opcodes}.a
    rm -f /usr/lib/libbz2.a
    rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
    rm -f /usr/lib/libltdl.a
    rm -f /usr/lib/libfl.a
    rm -f /usr/lib/libz.a

    find /usr/lib /usr/libexec -name \*.la -delete

    find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

    rm -rf /tools

-----
<a name="chapter9" />

## Chapter 9

### 9.2 Network Configuration

For my purpose it will be DHCP configuration

    cat > /etc/systemd/network/10-wlp2s0-dhcp.network << "EOF"
    [Match]
    Name=wlp2s0

    [Network]
    DHCP=ipv4

    [DHCP]
    UseDomains=true
    EOF

Link systemd-resolved DNS configuration: 

    ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf


Configure the hostname and /etc/hosts file

    echo "my_hostname" > /etc/hostname

    cat > /etc/hosts << "EOF"
    127.0.0.1 localhost my_hostname
    ::1       localhost
    EOF

### 9.8 Creating the /etc/inputrc File

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

Alternatively, just copy /etc/inputrc from the host system


### 9.9 Creating the /etc/shells file

    cat > /etc/shells << "EOF"
    # Begin /etc/shells

    /bin/sh
    /bin/bash

    # End /etc/shells
    EOF


-----
<a name="chapter10" />

## Chapter 10

### 10.2 Creating the /etc/fstab file

An example is given below. Customize for the specific system requirement

    cat > /etc/fstab << "EOF"
    /dev/sda1 /boot        ext2     defaults            0     0
    /dev/sda2 /            ext4     defaults            0     1
    /dev/sda3 /home        ext4     defaults,noatime    0     1    
    /dev/sda4 swap         swap     pri=1               0     0
    EOF

### 10.3 Building the kernel

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

        cp -v arch/x86/boot/bzImage /boot/mvlinux-5.8.3-lfs
        cp -v System.map /boot/System.map-5.8.3
        cp -v .config /boot/config-5.8.3

### 10.4 GRUB boot loader

 1. Install grub:

        grub-install /dev/sda

 2. Write the GRUB configuration file

        cat > /boot/grub/grub.cfg << "EOF"
        # Begin /boot/grub/grub.cfg
        set default=0
        set timeout=5

        insmod ext2
        set root=(hd0,1)

        menuentry "LFS 10.0-systemd - 5.8.3" {
                linux   /vmlinuz-5.8.3-lfs root=/dev/sda2 ro
        }
        EOF

-----
<a name="chapter11" />

## Chapter 11

### 11.1

These files are written when installing LFS package by PFSTools. Can ignore

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


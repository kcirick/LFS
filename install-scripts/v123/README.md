# LFS Installation Instructions

 -  Version: 12.3-Systemd [Link](https://www.linuxfromscratch.org/lfs/view/12.3-systemd/)
 -  Host: Debian stable Live (12.9.0)
    -  name: user / pass: live
    - Additional software needed: bison, gawk, m4, texinfo, wget
    - sudo apt-get install bison gawk m4 texinfo, wget


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
<a name="chapter2" /a>

## Chapter 2 

### 2.4 Creating a New Partition

An example partition:
 
    /dev/nvme0n1p1     fat32    /boot/efi    680 MB
        /nvme0n1p2     ext4     /boot        2GB
        /nvme0n1p3     ext4     /            96GB
        /nvme0n1p4     ext4     /home        139.8GB

Note the EFI partition requires special attention, see [BLFS GRUB setup](https://www.linuxfromscratch.org/blfs/view/systemd/postlfs/grub-setup.html)

Use parted to make the necessary partitions:

     (parted) mklabel gpt
     (parted) mkpart primary ext2 0 2048MB
     (parted) unit MB print free <-- check free space
     (parted) print

To format the partitions:

    mkfs.vfat -F 32 /dev/mmcblk0p1
    mkfs -v -t ext4 /dev/mmcblk0p2
    mkfs -v -t ext4 /dev/mmcblk0p3

There is no need to create a dedicated swap partition! A swap file can be added at any time later on and is more flexible while offering the same performance

To create swapfile:

    sudo fallocate -l 2G /swapfile
    
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile


To show the status of swapfile:

    sudo swapon --show

To unmount swapfile:

    sudo swapoff -v /swapfile
    sudo rm /swapfile

### 2.6/2.7 Setting the $LFS Variable

    export LFS=/mnt/lfs
    sudo mkdir $LFS
    sudo mount /dev/mmcblk0p3 $LFS

If we are mounting directories on separate partitions, mount them:

    sudo mkdir $LFS/boot
    sudo mount /dev/mmcblk0p2 $LFS/boot

    sudo mkdir $LFS/boot/efi
    sudo mount /dev/mmcblk0p1 $LFS/boot/efi

-----
<a name="chapter3" />

## Chapter 3

Create the source directory

    sudo mkdir $LFS/sources
    sudo chmod a+wt $LFS/sources

Download the packages and patches

    wget --input-file=list123_files.txt \
         --continue \
         --directory-prefix=$LFS/sources
    wget --input-file=list123_patches.txt \
         --continue \
         --directory-prefix=$LFS/sources

-----
<a name="chapter4" />

## Chapter 4

### 4.2 Creating the $LFS Directory Layout

     sudo mkdir -pv $LFS/{etc,var,tools} $LFS/usr/{bin,lib,lib64,sbin}

     for i in bin lib lib64 sbin; do
         sudo ln -sv usr/$i $LFS/$i
     done

### 4.3 Adding the LFS User

     sudo groupadd lfs
     sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
     sudo passwd lfs

Enter the password when prompted.

Next change the ownership of the folders

    sudo chown -v lfs $LFS/{usr{,/*},var,etc,tools}

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

 -  Follow chapter6.sh

-----
<a name="chapter7" />

## Chapter 7

  - Make sure to log out of lfs user, and that $LFS is set

### 7.2 Changing Ownership

    sudo chown --from lfs -R root:root $LFS/{usr,lib,lib64,var,etc,bin,sbin,tools}

### 7.3 Preparing Virtual Kernel File Systems

    sudo mkdir -pv $LFS/{dev,proc,sys,run}

Now mount system:

    sudo mount -v --bind /dev $LFS/dev

    sudo mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
    sudo mount -vt proc proc $LFS/proc
    sudo mount -vt sysfs sysfs $LFS/sys
    sudo mount -vt tmpfs tmpfs $LFS/run
    sudo mount -vt tmpfs tmpfs -o nosuid,nodev $LFS/dev/shm

find out which subsystem is mounted by:

    findmnt | grep $LFS


### 7.4 Entering the Chroot Environment

    sudo chroot $LFS /usr/bin/env -i    \
        HOME=/root                      \
        TERM="$TERM"                    \
        PS1='(lfs chroot) \u:\w\$ '     \
        PATH=/usr/bin:/usr/sbin         \
        MAKEFLAGS=“-j2”                \
        /bin/bash --login

It will say "I have no name!" in bash prompt.

### 7.5 and 7.6

 -  Follow chapter7-setup.sh

### 7.7 to 7.12

 -  Follow chapter7.sh

### 7.13 Cleaning up and Saving the Temporary System

Delete unneeded files and documents:

    find /usr/{lib,libexec} -name \*.la -delete

    rm -rf /usr/share/{info,man,doc}/*
    rm -rf /tools
    
    exit

Following are done outside of the chroot environment:

    sudo umount $LFS/dev/{pts,shm}
    sudo umount $LFS/{sys,proc,run,dev}

Strip off debugging symbols:

     sudo strip --strip-debug $LFS/usr/lib/*
     sudo strip --strip-unneeded $LFS/usr/{,s}bin/*

Create a back up file

     cd $LFS
     sudo tar --exlude='sources' -cJpf $HOME/lfs-temp-tools-12.3-systemd.tar.xz .

If a restore is needed:

     cd $LFS
     rm -rf ./* 
     tar -xpf $HOME/lfs-temp-tools-12.3-systemd.tar.xz


-----
<a name="chapter8" />

## Chapter 8

**Make sure the virtual kernel file system is setup and under chroot environment before continuing!** 

### 8.2 Package Management

Think about using pfstool for LFS. Currently used only for BLFS.


### 8.3 to 8.79

 -  follow chapter8.sh
    - Perform tests after 8.29
 -  Create root password


 -  Run 'logout' to log out before proceeding to section 8.76


 - Note the EFI partition requires special attention, see [BLFS GRUB setup](https://www.linuxfromscratch.org/blfs/view/systemd/postlfs/grub-setup.html)


### 8.83 Stripping Again

**This section is optional.**

Re-enter the chroot environment:

    chroot $LFS /usr/bin/env -i            \
        HOME=/root TERM=$TERM PS1='(chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
        /usr/bin/bash --login

Then strip by running chapter8-stripping.sh

### 8.84 Cleaning up

    rm -rf /tmp/{*,.*}

    find /usr/{lib,libexec} -name \*.la -delete

    find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

    rm -rf /tools

-----
<a name="chapter9" />

## Chapter 9

### 9.2 Network Configuration

For my purpose it will be DHCP configuration

    cat > /etc/systemd/network/10-wlp0s12f0-dhcp.network << "EOF"
    [Match]
    Name=wlp0s12f0

    [Network]
    DHCP=ipv4

    [DHCPv4]
    UseDomains=true
    EOF


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

    #/dev/sda1 /boot        ext2     defaults            0     0
    #/dev/sda2 /            ext4     defaults            0     1
    #/dev/sda3 /home        ext4     defaults,noatime    0     1    
    UUID=8F8A-1496    /boot/efi vfat    umask=0077,codepage=437,iocharset=iso8859-1 0 2
    UUID=bbabb61fa-***  /       ext4    defaults,noatime        0   1
    ...

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

        cp -v arch/x86/boot/bzImage /boot/vmlinuz-6.14.1-lfs-x
        cp -v System.map /boot/System.map-6.14.1-lfs-x
        cp -v .config /boot/config-6.14.1-lfs-x

### 10.4 GRUB boot loader

**TODO:** Alternative is systemd-boot (no need for grub)

 1. Install grub:

        grub-install --target=x86_64-efi --removable

mountpoint /sys/firmware/efi/efivars || mount -v -t efivarfs efivarfs /sys/firmware/efi/efivars

        grub-install --bootloader-id=LFS --recheck

check with

       efibootmgr | cut -f 1

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

or do:

      grub-mkconfig -o /boot/grub/grub.cfg

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


### 11.3 Rebooting the system

First logout from the chroot environment:

    logout

Then unmount whatever is mounted:

    unmount -v $LFS/dev/pts
    mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
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
 3.  iw, wpa_supplicant, wget



# Installation Instructions

 -  Version: 9.1-Systemd [Link](http://www.linuxfromscratch.org/lfs/view/stable-systemd/)
 -  Host: Salix Live XFCE 14.1
   - root passwd = "one"

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

Use gparted to partition the hard drive. eg:
 

	/dev/sda1     ext2     /boot    1   GiB
	    /sda2     ext4     /        250 GiB
	    /sda3     ext4     /home    Rest


### 2.6/2.7 Setting the $LFS Variable

    export LFS=/mnt/lfs
    sudo mkdir $LFS
    sudo mount /dev/sda2 $LFS

If we are mounting directories on separate partitions, mount them:

    sudo mkdir $LFS/boot
    sudo mount -t ext2 /dev/sda1 $LFS/boot
    sudo mkdir $LFS/home
    sudo mount -t ext4 /dev/sda3 $LFS/home

-----
<a name="chapter3" />
## Chapter 3

Create the source directory

    sudo mkdir $LFS/sources
    sudo chmod a+wt $LFS/sources

Download the packages and patches

    wget --input-file=list91_files.txt \
         --continue \
         --directory-prefix=$LFS/sources
    wget --input-file=list91_patches.txt \
         --continue \
         --directory-prefix=$LFS/sources

-----
<a name="chapter4" />
## Chapter 4

### 4.2 Creating the $LFS/tools Directory

     sudo mkdir $LFS/tools
     sudo ln -sv $LFS/tools /

You should see the following output:

     '/tools' -> '/mnt/lfs/tools'

### 4.3 Adding the LFS User

     sudo groupadd lfs
     sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
     sudo passwd lfs

Enter the password when prompted.

Next change the ownership of the folders

    chown -v lfs $LFS/sources
    chown -v lfs $LFS/tools

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
    PATH=/tools/bin:/bin:/usr/bin
    export LFS LC_ALL LFS_TGT PATH
    EOF

Then load the profile:

    source ~/.bash_profile


-----
<a name="chapter5" />
## Chapter 5

 -  follow 91-chapter5.sh
   - Perform tests at the end of 5.7 and 5.10
 -  5.36: Changing ownership:
        
        chown -R root:root $LFS/tools

 -  At the end of the script, create back up of $LFS/tools

        tar -Jcvf tools91.tar.xz $LFS/tools
 

-----
<a name="chapter6" />
## Chapter 6

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

### 6.7 to 6.69

 -  follow 79-chapter6.sh
   - Perform tests after 6.10 and 6.17
   - Set root password at 6.25
 -  Create root password
 -  Remember to run

        mv -v /usr/bin/[ /bin

 -  Run 'logout' to log out before proceeding to section 6.71

### 6.71 Stripping Again

Re-enter the chroot environment:

    chroot $LFS /tools/bin/env -i            \
        HOME=/root TERM=$TERM PS1='\u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
        /tools/bin/bash --login

Then strip:

    /tools/bin/find /{,usr/}{bin,lib,sbin} -type f -exec /tools/bin/strip --strip-debug '{}' ';'

### 6.72 Cleaning up

    rm -rf /tmp/*
    rm -f /usr/lib/lib{bfd,opcodes}.a
    rm -f /usr/lib/libbz2.a
    rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
    rm -f /usr/lib/libltdl.a
    rm -f /usr/lib/libfl.a
    rm -f /usr/lib/libfl_pic.a
    rm -f /usr/lib/libz.a


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



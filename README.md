Bootstrap-OpenSUSE
==================

Author : Marc Wäckerlin

local GITHUB  copy of https://marc.waeckerlin.org/computer/blog/bootstrap_opensuse


 Bootstrapping a running openSUSE into a chroot was simpler than I thought:

    Just get the basic RPMs for glibc, bash, rpm and zypper including all dependencies.
    Unpack them into a chroot-path using cpio
    Tweak the minimal system in /etc, add root to /etc/passwd and copy resolv.conf for internet access
    bind /dev from the real system to the chroot
    Chroot into that minimal installation and install all the RPM packages once again, this time correctly using rpm; that fixes the RPM database and runs the necessary scripts
    Add an archive to zypper
    Done, now chroot to the path and install whatever you need using zypper

marcs bash script "oss11.4-bootstap.sh" that He run on Ubuntu to bootstrap a basic openSUSE 11.4  attached to this repo.



Why Bootstrap an OS into a Chroot

The chroot helps you build openSUSE RPMs with the correct dependencies on another host system. Fo example I build openSUSE RPMs on Ubuntu within a chroot.
Why not use «mach» or «mock»

There are tools named mach and its unfriendly fork mock to make a chroot of a rpm-based distribution to build rpm packages inside a chroot. My only problem was, the're quite complex and did not work out of the box.- mock is not maintained in Ubuntu and has been dropped, while the packache mach in Ubuntu only provides old SuSE and Fedora releases, up to SuSE 9, but now when writing these lines, openSUSE 11.4 is the current release. So not useful for me and too complex to fix. That's why I started from scratch.
Fedora

The same trick should work on Fedora. I'll try this later and change the script so that Fedora will be supported too.
Working

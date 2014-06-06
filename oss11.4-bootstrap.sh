#! /bin/bash -e
 
function error() {
    echo "**** ERROR aborted. Status of last operation: $?"
    if mount | grep -q ${ROOT}/dev; then
        echo "cleanup ${ROOT}/dev"
        sudo umount ${ROOT}/dev
    fi
    exit 1
}
trap error HUP INT QUIT TERM ERR
 
################################################################################
# CONFIGURATION you can overwrite any of the variables when you start the script
# e.g. HW="x86_64 noarch" VERSION=11.4 sudo susebootstrap.sh
 
# Setup OS sources
#
# VERSION: see http://download.opensuse.org/distribution/
VERSION=${VERSION:-"openSUSE-current"}
#
# HW: list of hardware subdirs in openSUSE, e.g. "x86_64 noarch"
HW=(${HW:-i686 i586 noarch})
#
# URL: where to download RPM packages from
URL=${URL:-http://download.opensuse.org/distribution/${VERSION}/repo/oss/suse}
 
# Setup installation pathes
#
# BASE: Base path to the chroots on your system
BASE=${BASE:-/var/chroot}
#
# OS: name of the OS, used for chroot pathname
OS=${OS:-opensuse}
#
# ROOT: Full path to the chroot directory
ROOT=${ROOT:-${BASE}/${OS}-${VERSION}-${HW[0]}}
#
# PACKAGES: Where to store package lists path+filename-prefix
PACKAGES=${PACKAGES:-${ROOT}/var/tmp/packages}
#
# RPMDIR: Where to store downloaded RPMs, relative to ${ROOT}
RPMDIR=${RPMDIR:-/var/tmp/rpms}
 
# Setup base packages and dependencies to install
#
# Dependencies, found out by try and error using "rpm -i"
GLIBCDEPS="filesystem"
BASHDEPS="libreadline6 libncurses5 terminfo-base"
RPMDEPS="libpopt0 liblua5_1 libselinux1 libcap2 libacl libbz2 zlib     \
         libelf1 liblzma5 libattr insserv sed fillup coreutils grep    \
         diffutils permissions perl info pam libpcre0 perl-base gdbm   \
         libzio libaudit1 libcrack2 libdb file cracklib libxcrypt      \
         cracklib-dict-full"
ZYPPERDEPS="procps libzypp libaugeas libgcc libstdc++ satsolver-tools  \
            util-linux libcurl4 libopenssl1 libexpat libproxy1 libxml2 \
            krb5 libidn libldap libssh2 libmodman libgconf libglib     \
            libcom_err2 keyutils-libs cyrus-sasl gpg2 libudev gzip     \
            bzip2 pwdutils pinentry dirmngr libadns libassuan          \
            libgcrypt libgpg-error libksba libpth libusb pam-modules   \
            libnscd libblkid libmount libuuid1 openssl                 \
            update-alternatives glib2-branding-openSUSE"
#
# RPMS: Base packages to install including dependencies from above
RPMS=${RPMS:-bash glibc rpm zypper $GLIBCDEPS $BASHDEPS $RPMDEPS $ZYPPERDEPS}
################################################################################
 
 
################################################################################
# Main Part
################################################################################
# 1. Download basic RPMs for glibc, bash, rpm, zypper and all dependencies
# 2. Unpack them into a chroot-path using cpio
# 3. Tweak the minimal system in /etc
# 4. Bind /dev from the real system to the chroot
# 5. Properly install all the RPM packages within chroot
# 6. Add an archive to zypper and setup hardware architecture
# 7. Done, now chroot to the path and install whatever you need using zypper
################################################################################
 
echo "Install ${OS} ${VERSION} for ${HW[0]} in ${ROOT}"
 
################################################################################
# Preparation of path for chroot and RPMs
test -d ${ROOT}${RPMDIR} || mkdir -p ${ROOT}${RPMDIR}
################################################################################
 
################################################################################
# For all hardware subdirs, get a list of available RPMs from internet
# stored in files ${PACKAGES}.<HARDWARE>
for h in ${HW[*]}; do
    wget -q -O - ${URL}/${h} 2>/dev/null \
        | sed -n 's/.*<a href="\(.*\.'${h}'\.rpm\)">.*/\1/p' \
        > ${PACKAGES}.${h}
done
################################################################################
 
################################################################################
# 1. Download basic RPMs for glibc, bash, rpm, zypper and all dependencies
 
# We know the logical package names, find matching RPM files on server
# PKGS: Will be filled with a list of RPM files to download and install
PKGS=""
for p in $RPMS; do # for all packages to instaöö
    for h in ${HW[*]}; do # for all available hardware subdirectories
        # find all packages that match the package we're looking for
        # but without "-devel" oder "-doc" packages
        if [ "${h}" = "x86_64" ]; then
            # in 64bit package lists, there are also 32bit compatibility
            # packages
            # we filter them out, we want a plain 64bit installation
            PKG=$(egrep '^'${p//+/\\+}'[-0-9_][-0-9_]' "${PACKAGES}.${h}" \
                | egrep -v -- '-devel-|32bit|-doc-' | sort)
        else
            # same as above, without filtering 32bit
            PKG=$(egrep '^'${p//+/\\+}'[-0-9_][-0-9_]' "${PACKAGES}.${h}" \
                | egrep -v -- '-devel-|-doc-' | sort)
        fi
        if [ -n "$PKG" ]; then # We've found at least one matching package
            for p2 in $PKG; do # for all RPM packages  we found
                # if not yet downloaded, download it now
                echo "   ... download $p2"
                test -f ${ROOT}${RPMDIR}/$p2 || \
                    wget -q -O ${ROOT}${RPMDIR}/$p2 ${URL}/${h}/$p2
                # append RPMs to the list of RPM files to install
                PKGS="$PKGS ${ROOT}${RPMDIR}/$p2"
            done
            break # take the first, no need to further scan hardware directories
        fi
    done
done
################################################################################
 
################################################################################
# 2. Unpack them into a chroot-path using cpio
 
# Extract all downloaded RPMS in the chroot directory
cd ${ROOT}
for p in $PKGS; do # for all downloaded RPM packages
    # just extract the file structure withing the RPM without running
    # pre-/post-install scripts
    # this is necessary for a minimal basic system to chroot in
    echo "   ... unpack $p"
    rpm2cpio $p | sudo cpio -dim --quiet
done
cd -
################################################################################
 
################################################################################
# 3. Tweak the minimal system in /etc
echo "   ... setup system"
 
# Do some system setup tweaks
#
# Create minimal /etc/passwd with user "root"
sudo bash -c "echo 'root:x:0:0:root:/root:/bin/bash' > ${ROOT}/etc/passwd"
#
# copy /etc/resolv.conf into chroot to be able to access internet
sudo cp /etc/resolv.conf ${ROOT}/etc/
 
################################################################################
# 4. Bind /dev from the real system to the chroot
 
# rebind host's /dev into chroot to be able to access hardware within chroot
# NOTE: this step must be repeated (or use "schroot")
sudo mount -o bind /dev ${ROOT}/dev
 
################################################################################
# 5. Properly install all the RPM packages within chroot
 
# now chroot into the newe system and call RPM on all donwloaded RPMs for
# a proper installation that executes triggers and maintains RPM database
echo "   ... install all RPMs"
sudo chroot ${ROOT} rpm -i ${RPMDIR}/*.rpm 2> /dev/null
 
################################################################################
# 6. Add an archive to zypper and setup hardware architecture
# add installation source as zypper repository
echo "   ... setup zypper"
sudo chroot ${ROOT} zypper -q ar ${URL} repo-oss
#
# setup hardware architecture in zypper, necessary if not same as in host
sudo perl -pi \
    -e 's#^\#? *arch = .*$#arch = '${HW[0]}'#g' \
    ${ROOT}/etc/zypp/zypp.conf
################################################################################
 
################################################################################
# Done - use your chroot, install more packages with zypper
################################################################################
 
################################################################################
# 7. Done, now chroot to the path and install whatever you need using ''zypper'
# on opensuse, install some basic packages
echo "   ... install more basic packages"
sudo chroot ${ROOT} zypper -q install aaa_base openSUSE-release
################################################################################
 
################################################################################
################################################################################
# cleanup: umount /dev
# NOTE: you must bind it again, if you want to chroot (or use "schroot")
echo "   ... cleanup"
sudo umount ${ROOT}/dev
################################################################################
 
echo "**** SUCCESS done."
echo
echo "########################################################################"
echo "Use your new chroot:"
echo " > sudo mount -o bind /dev ${ROOT}/dev"
echo " > sudo chroot ${ROOT}"
echo "   > [... work in your chroot, use zypper to install packages ...]"
echo "   > exit"
echo " > sudo umount ${ROOT}/dev"
echo "########################################################################"
echo "IMPORTANT NOTE:"
echo "  Don't forget to umount /dev and other binds before you remove"
echo "  the directory ${ROOT},"
echo "  or you'll loose"
echo "########################################################################"

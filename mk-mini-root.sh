#!/bin/sh

set -x

# cleanup
test -d /VM/test2/chroot && rm -rf  /VM/test2/chroot
#
# chroot basedirs
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/etc
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/root
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/tmp
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/home
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/bin
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/opt
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/sbin
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/proc
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/media
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/lib

mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/run
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/log
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/lock
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/adm
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/opt
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/spool
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/crash
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/var/tmp


mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/lib
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/bin
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/sbin
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/share
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/local
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/include
mkdir -p /VM/test2/chroot/opensuse-13.1-x86_64/usr/src


##We realy need  the base sample users

# from opensuse 13.1 desktop
cat >>/VM/test2/chroot/opensuse-13.1-x86_64/etc/passwd << EOF
root:x:0:0:root:/root:/bin/bash
lp:x:4:7:Printing daemon:/var/spool/lpd:/bin/bash
mail:x:8:12:Mailer daemon:/var/spool/clientmqueue:/bin/false
news:x:9:13:News system:/etc/news:/bin/bash
uucp:x:10:14:Unix-to-Unix CoPy system:/etc/uucp:/bin/bash
man:x:13:62:Manual pages viewer:/var/cache/man:/bin/bash
wwwrun:x:30:8:WWW daemon apache:/var/lib/wwwrun:/bin/bash
nobody:x:65534:65533:nobody:/var/lib/nobody:/bin/bash
EOF


cat >>/VM/test2/chroot/opensuse-13.1-x86_64/etc/group << EOF
root:x:0:
tty:x:5:
lp:x:7:
www:x:8:
mail:x:12:
news:x:13:
uucp:x:14:
shadow:x:15:
dialout:x:16:
audio:x:17:
utmp:x:22:
man:x:62:
nobody:x:65533:
EOF

cat >>/VM/test2/chroot/opensuse-13.1-x86_64/etc/shadow << EOF
root:!::::::
lp:*:16045::::::
mail:*:16045::::::
news:*:16045::::::
uucp:*:16045::::::
man:*:16045::::::
wwwrun:*:16045::::::
nobody:*:16045::::::
EOF

cat >>/VM/test2/chroot/opensuse-13.1-x86_64/etc/gshadow << EOF
abuild:*::
EOF


rpm -i --root  /VM/test2/chroot/opensuse-13.1-x86_64/ /proj/ossbootstrap/chroot-rpms/*.rpm

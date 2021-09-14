#!/bin/sh
# Evan Widloski - 2019-03-21
# Modified Entware installer from http://bin.entware.net/armv7sf-k3.2/installer/generic.sh

set -e
cleanup() {
    echo "Encountered error.  Cleaning up and quitting..."
    # get out of /opt so it can be unmounted
    cd /home/root

    if [ -d /opt ]
    then
        umount /opt
        rm /opt -rf
    fi

    if [ -d /home/root/.entware ]
    then
        rm /home/root/.entware -rf
    fi

    if [ -f /etc/systemd/system/opt.mount ]
    then
        rm /etc/systemd/system/opt.mount
    fi
}
trap cleanup ERR

unset LD_LIBRARY_PATH
unset LD_PRELOAD

echo "Info: Checking for prerequisites and creating folders..."

if [ -d /opt ]
then
    echo "Error: Folder /opt exists! Quitting..."
    exit 1
else
    if [ -d /home/root/.entware ]
    then
        echo "Error: Folder /home/root/.entware exists! Quitting..."
        exit 1
    else
        mkdir /opt
        # mount /opt in /home for more storage space
        mkdir -p /home/root/.entware
        mount --bind /home/root/.entware /opt
    fi
fi

# create systemd mount unit to mount over /opt on reboot
cat >/etc/systemd/system/opt.mount <<EOF
[Unit]
Description=Bind mount over /opt to give entware more space
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target

[Mount]
What=/home/root/.entware
Where=/opt
Type=none
Options=bind

[Install]
WantedBy=local-fs.target
EOF
systemctl daemon-reload
systemctl enable opt.mount


# no need to create many folders. entware-opt package creates most
for folder in bin etc lib/opkg tmp var/lock
do
  if [ -d "/opt/$folder" ]
  then
    echo "Warning: Folder /opt/$folder exists!"
    echo "Warning: If something goes wrong please clean /opt folder and try again."
  else
    mkdir -p /opt/$folder
  fi
done

echo "Info: Opkg package manager deployment..."
DLOADER="ld-linux.so.3"
URL=http://bin.entware.net/armv7sf-k3.2/installer
wget $URL/opkg -O /opt/bin/opkg
chmod 755 /opt/bin/opkg
wget $URL/opkg.conf -O /opt/etc/opkg.conf
wget $URL/ld-2.27.so -O /opt/lib/ld-2.27.so
wget $URL/libc-2.27.so -O /opt/lib/libc-2.27.so
wget $URL/libgcc_s.so.1 -O /opt/lib/libgcc_s.so.1
wget $URL/libpthread-2.27.so -O /opt/lib/libpthread-2.27.so

# validate integrity of downloaded files
precomputed_hash="c965366080b8d2004cde8e34ebb9f910  -"
hash=$(cat /opt/bin/* /opt/etc/* /opt/lib/* | md5sum)
if [ "$hash" = "$precomputed_hash" ]
then
    echo pass
else
    echo "Computed hash did not match."
    exit 1
fi

cd /opt/lib
chmod 755 ld-2.27.so
ln -s ld-2.27.so $DLOADER
ln -s libc-2.27.so libc.so.6
ln -s libpthread-2.27.so libpthread.so.0

/opt/bin/opkg update
/opt/bin/opkg install entware-opt wget ca-certificates

sed -i 's|http://|https://|g' /opt/etc/opkg.conf

# Fix for multiuser environment
chmod 777 /opt/tmp

# now try create symlinks - it is a std installation
if [ -f /etc/passwd ]
then
    ln -sf /etc/passwd /opt/etc/passwd
else
    cp /opt/etc/passwd.1 /opt/etc/passwd
fi

if [ -f /etc/group ]
then
    ln -sf /etc/group /opt/etc/group
else
    cp /opt/etc/group.1 /opt/etc/group
fi

if [ -f /etc/shells ]
then
    ln -sf /etc/shells /opt/etc/shells
else
    cp /opt/etc/shells.1 /opt/etc/shells
fi

if [ -f /etc/shadow ]
then
    ln -sf /etc/shadow /opt/etc/shadow
fi

if [ -f /etc/gshadow ]
then
    ln -sf /etc/gshadow /opt/etc/gshadow
fi

if [ -f /etc/localtime ]
then
    ln -sf /etc/localtime /opt/etc/localtime
fi


echo ""
echo "Info: Congratulations! Entware has been installed."
echo "Info: Add /opt/bin & /opt/sbin to your PATH by executing"
echo 'ssh root@10.11.99.1 echo '\\\'\''PATH=/opt/bin:/opt/sbin:$PATH'\'\\\'\'' >> ~/.bashrc'\'

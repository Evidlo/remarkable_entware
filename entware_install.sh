#!/bin/sh

echo "Info: Checking for prerequisites and creating folders..."

if [ -d /opt ]
then
    echo "Error: Folder /opt exists! Quitting..."
    exit
else
    mkdir /opt

    if [ -d /home/root/.entware ]
    then
        echo "Error: Folder /home/root/.entware exists! Quitting..."
        exit
    else
        # mount /opt in /home for more storage space
        mkdir -p /home/root/.entware
        mount --bind /home/root/.entware /opt
    fi
fi


for folder in bin etc/init.d lib/opkg sbin share tmp usr var/log var/lock var/run
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
CURARCH="armv7"
DLOADER="ld-linux.so.3"
URL=http://pkg.entware.net/binaries/$CURARCH/installer
wget $URL/opkg -O /opt/bin/opkg
chmod +x /opt/bin/opkg
wget $URL/opkg.conf -O /opt/etc/opkg.conf
wget $URL/ld-2.23.so -O /opt/lib/ld-2.23.so
wget $URL/libc-2.23.so -O/opt/lib/libc-2.23.so
wget $URL/libgcc_s.so.1.2.23 -O /opt/lib/libgcc_s.so.1
cd /opt/lib
chmod +x ld-2.23.so
ln -s ld-2.23.so $DLOADER
ln -s libc-2.23.so libc.so.6

echo "Info: Basic packages installation..."
/opt/bin/opkg update
/opt/bin/opkg install entware-opt
if [ ! -f /opt/usr/lib/locale/locale-archive ]
then
        wget http://pkg.entware.net/binaries/other/locale-archive.2.23 -O /opt/usr/lib/locale/locale-archive
fi

# from Entware (2018)
# now try create symlinks - it is a std installation
if [ -f /etc/passwd ]
then
    ln -sf /etc/passwd /opt/etc/passwd
fi

if [ -f /etc/group ]
then
    ln -sf /etc/group /opt/etc/group
fi

if [ -f /etc/shells ]
then
    ln -sf /etc/shells /opt/etc/shells
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

# Upgrading to Entware
/opt/bin/opkg update
/opt/bin/opkg upgrade

# create systemd mount unit to mount over /opt on reboot
parent_dir=$(dirname $0)
cp $parent_dir/opt.mount /etc/systemd/system/
systemctl daemon-reload
systemctl enable opt.mount

echo "Info: Congratulations!"
echo "Info: If there are no errors above then Entware has been installed."
echo "Info: Add /opt/bin & /opt/sbin to your PATH variable"

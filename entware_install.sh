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

    if [ -e /home/root/.wget_bin ]
    then
        rm /home/root/.wget_bin -rf
    fi
}
trap cleanup ERR

unset LD_LIBRARY_PATH
unset LD_PRELOAD

echo "Info: Checking for prerequisites and creating folders..."

if [ -d /opt ]
then
    echo "Error: Folder /opt exists! Quitting..."
    exit
else
    if [ -d /home/root/.entware ]
    then
        echo "Error: Folder /home/root/.entware exists! Quitting..."
        exit
    else
        mkdir /opt
        # mount /opt in /home for more storage space
        mkdir -p /home/root/.entware
        mount --bind /home/root/.entware /opt
    fi
fi

if [ ! -d /home/root/.wget_bin ]
then
    # Bootstrap a current version of wget
    WGET_BINARIES_PATH='http://static.cosmos-ink.net/remarkable/artifacts'
    WGET_BINARIES_FILENAME='wget-remarkable-pipeline_job245_wget1.20.3.zip'
    WGET_BINARIES_SHA256='84185a5934e34e25794d439c78dc9f1590e4df12fbf369236f6a8749bf14d67f'

    # Download and compare to hash
    wget "$WGET_BINARIES_PATH/$WGET_BINARIES_FILENAME" -O "/home/root/$WGET_BINARIES_FILENAME"
    if ! echo "$WGET_BINARIES_SHA256  /home/root/$WGET_BINARIES_FILENAME" | sha256sum -c -
    then
        echo "FATAL: Invalid hash" >&2
        exit 1
    fi

    # Ensure to /home/root/.wget_bin exists and is empty
    if [ -d /home/root/.wget_bin ]
    then
        rm -rf /home/root/.wget_bin/*
    else
        mkdir /home/root/.wget_bin
    fi
    # Unzip to /home/root/.wget_bin and remove downloaded file
    unzip "/home/root/$WGET_BINARIES_FILENAME" -d /home/root/.wget_bin -q
    rm "/home/root/$WGET_BINARIES_FILENAME"

    cat > /home/root/.wget_bin/wget <<EOF
#!/bin/sh
LD_LIBRARY_PATH="/home/root/.wget_bin/dist" /home/root/.wget_bin/dist/wget \$@
EOF

    chmod +x /home/root/.wget_bin/wget
    PATH="/home/root/.wget_bin:$PATH"
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
URL=https://bin.entware.net/armv7sf-k3.2/installer
wget $URL/opkg -O /opt/bin/opkg
chmod 755 /opt/bin/opkg
wget $URL/opkg.conf -O /opt/etc/opkg.conf
wget $URL/ld-2.27.so -O /opt/lib/ld-2.27.so
wget $URL/libc-2.27.so -O /opt/lib/libc-2.27.so
wget $URL/libgcc_s.so.1 -O /opt/lib/libgcc_s.so.1
wget $URL/libpthread-2.27.so -O /opt/lib/libpthread-2.27.so
cd /opt/lib
chmod 755 ld-2.27.so
ln -s ld-2.27.so $DLOADER
ln -s libc-2.27.so libc.so.6
ln -s libpthread-2.27.so libpthread.so.0

echo "INFO: Adding repo for reMarkable software"
echo 'src/gz toltec https://toltec.delab.re/stable' >> /opt/etc/opkg.conf

sed -i 's|http://|https://|g' /opt/etc/opkg.conf
echo "Info: Basic packages installation..."
/opt/bin/opkg update
/opt/bin/opkg install entware-opt wget ca-certificates

# No more needed
rm /home/root/.wget_bin -rf

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

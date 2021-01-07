#!/bin/sh
# Evan Widloski - 2019-03-21
# Re-enable entware after reMarkable update

set -e

mkdir /opt
mount --bind /home/root/.entware /opt

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

echo ""
echo "Info: Entware has been re-enabled."

# Hooks
HOOKS_DIR=/opt/etc/remarkable_entware_reenable.d
if [ -d $HOOKS_DIR ]; then
  echo "Info: Running hooks..."
  for hook in $HOOKS_DIR/*; do
    if ! $hook; then
      echo "Hook failed:" `basename "$hook"` >&2
    fi
  done
  echo "Info: Hooks completed"
fi

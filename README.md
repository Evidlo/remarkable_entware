# reMarkable Entware

This is a modified installer for [Entware](https://github.com/Entware/Entware), a lightweight package manager and software repo for embedded devices.

See a list of available packages [here](http://bin.entware.net/armv7sf-k3.2/).

### Installation

Connect your device to the internet before executing.

``` bash
scp entware_install.sh root@10.11.99.1:
ssh root@10.11.99.1 ./entware_install.sh
```

All entware data is located in `/opt` (which actually points to `/home/root/.entware` because of size constraints on the root partition).  Base installation is ~13MB.

### Examples

``` bash
opkg install git
opkg find '*top*'    # search package names and descriptions
```

### After a reMarkable update

reMarkable updates wipe out everything outside of `/home/root`.  While Entware remains intact in `/home/root/.entware`, the mount over `/opt` has to be recreated with `entware_reenable.sh`.

``` bash
scp entware_reenable.sh root@10.11.99.1
ssh root@10.11.99.1 ./entware_reenable.sh
```

### No space left on device

You can clean up logfiles which take up considerable space on the root partition.

    journalctl --vacuum-size=2M

# reMarkable Entware

This is a modified installer for [Entware](https://github.com/Entware/Entware), a lightweight package manager and software repo for embedded devices.

If you'd like to install reMarkable specific packages, you should install [Toltec](https://toltec-dev.org) instead, which includes the Entware repositories as well as graphical applications fo rthe reMarkable.

See a list of available entware packages here: http://bin.entware.net/armv7sf-k3.2/.

### Installation

Connect the reMarkable via USB and make sure it has internet access.

Connect to the reMarkable with [SSH](https://remarkablewiki.com/tech/ssh) and execute

``` bash
wget -O - http://raw.githubusercontent.com/Evidlo/remarkable_entware/master/install.sh | sh
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
wget -O - http://raw.githubusercontent.com/Evidlo/remarkable_entware/master/reenable.sh | sh
```

### No space left on device

You can clean up logfiles which take up considerable space on the root partition.

``` bash
journalctl --vacuum-size=2M
```

# reMarkable Entware

This is a modified installer for [Entware](https://github.com/Entware/Entware), a lightweight package manager and software repo for embedded devices.

See a list of available packages [here](http://bin.entware.net/armv7sf-k2.6/).

# Installation

Connect your device to the internet before executing.

``` bash
scp entware_install.sh opt.mount root@10.11.99.1:
ssh root@10.11.99.1 ./entware_install.sh
```

All entware data is located in `/opt` (which actually points to `/home/root/.entware` because of size constraints on the root partition).  Base installation is ~13MB.

# Example

``` bash
opkg install git
opkg search '*top*'  # search package names
opkg find '*top*'    # search package names and descriptions
```

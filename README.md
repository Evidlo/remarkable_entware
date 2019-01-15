# reMarkable Entware

[Entware](https://github.com/Entware/Entware) package manager and software repo for the reMarkable tablet.

# Installation

Connect your device to the internet before executing.

``` bash
scp entware_install.sh opt.mount root@10.11.99.1:
ssh root@10.11.99.1 ./entware_install.sh
```

All entware data is located in `/opt` (which actually points to `/home/root/.entware` because of size constraints on the root partition).  Base installation is ~13MB.

# Usage

``` bash
opkg install git
```

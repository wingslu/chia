#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin




# parted /dev/sda mklabel gpt
# parted /dev/sdb mklabel gpt
# parted /dev/sdc mklabel gpt
# parted /dev/sdd mklabel gpt
# parted /dev/sde mklabel gpt
# parted /dev/sdf mklabel gpt


# parted /dev/sda mkpart primary 0% 100%
# parted /dev/sdb mkpart primary 0% 100%
# parted /dev/sdc mkpart primary 0% 100%
# parted /dev/sdd mkpart primary 0% 100%
# parted /dev/sde mkpart primary 0% 100%
# parted /dev/sdf mkpart primary 0% 100%


# mkfs.ext4 /dev/sda1
# mkfs.ext4 /dev/sdb1
# mkfs.ext4 /dev/sdc1
# mkfs.ext4 /dev/sdd1
# mkfs.ext4 /dev/sde1
# mkfs.ext4 /dev/sdf1


# mount /dev/sda1 /chia_plots_disk/1
# mount /dev/sdb1 /chia_plots_disk/2
# mount /dev/sdc1 /chia_plots_disk/3
# mount /dev/sdd1 /chia_plots_disk/4
# mount /dev/sde1 /chia_plots_disk/5
# mount /dev/sdf1 /chia_plots_disk/6
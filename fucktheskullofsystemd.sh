#!/bin/sh
# nous,2019-2020

# How to use
# wget https://tiny.cc/fucksystemd
# chmod +x fucksystemd
# sudo ./fucksystemd

# Test Arch ISO installation:
# cfdisk /dev/sda
# mkfs.ext4 /dev/sda1
# mount /dev/sda1 /mnt
# pacstrap /mnt base linux linux-firmware openssh wget rsync dhcpcd grub
# arch-chroot /mnt
# grub-install /dev/sda
# mkinitcpio -P
# grub-mkconfig -o /boot/grub/grub.cfg

source /usr/share/makepkg/util/message.sh
colorize

echo "$BOLD You should run this from inside screen(1) or tmux(1),"
echo "$BOLD especially if this is a remote box."
echo "$BOLD Use a terminal/session with a large scrollback buffer"
echo
echo "$RED Last chance to press CTRL-C, ENTER to continue."
read
echo
echo "$CYAN Starting operation FUCKTHESKULLOFSYSTEMD"
echo

testerror() { [[ $res > 0 ]] && { echo "$RED An error occured, aborting to prevent incomplete conversion. Fix it and re-run the script FROM THE LAST STEP ONWARDS."; exit 1; } }
[[ $1 == openrc ]] && target=openrc
[[ $1 == runit ]] && target=runit

# runit not yet implemented
#[[ $target ]] || { echo "Usage: $0 <openrc|runit>" ; exit 1; }
#echo "Target: $target"

rm -f /var/lib/pacman/db.lck
sed -i s/Arch/Artix/g /etc/default/grub
# A full systemd update is needed, because libsystemd->systemd-libs
echo "$GREEN Updating system first, if this fails abort and update manually; then re-run the script $ALL_OFF"
pacman -Syu --noconfirm
res=$?; testerror
pacman -S --needed --noconfirm wget nano
res=$?; testerror

cd /etc
echo
echo "$GREEN Replacing Arch repositories with Artix $ALL_OFF"
mv -vf pacman.conf pacman.conf.arch
wget https://gitea.artixlinux.org/packagesP/pacman/raw/branch/master/trunk/pacman.conf -O /etc/pacman.conf
res=$?; testerror
mv -vf pacman.d/mirrorlist pacman.d/mirrorlist-arch
wget https://gitea.artixlinux.org/packagesA/artix-mirrorlist/raw/branch/master/trunk/mirrorlist -O pacman.d/mirrorlist
res=$?; testerror
cp -vf pacman.d/mirrorlist pacman.d/mirrorlist.artix
sed -i 's/Required DatabaseOptional/Never/' pacman.conf

echo "$GREEN Refreshing package databases $ALL_OFF"
pacman -Syy --noconfirm
res=$?; testerror
echo
echo "$GREEN Press ENTER and answer <yes> to the next question to make sure all packages come from Artix repos $ALL_OFF"
echo
read
pacman -Scc

echo "$GREEN Importing Artix keys $ALL_OFF"
pacman -S --noconfirm artix-keyring
res=$?; testerror
pacman-key --populate artix
res=$?; testerror
pacman-key --lsign-key 95AEC5D0C1E294FC9F82B253573A673A53C01BC2
res=$?; testerror

systemctl list-units --state=running | grep -v systemd | awk '{print $1}' | grep service > /root/daemon.list
echo "$MAGENTA Your systemd running units are saved in /root/daemon.list.$ALL_OFF"
echo
echo "$RED Do not proceed if you've seen errors above - press CTRL-C to abort or ENTER to continue $ALL_OFF"
read
echo
echo "$GREEN Downloading systemd-free packages from Artix $ALL_OFF"
pacman -Sw --noconfirm base base-devel openrc-system grub linux-lts linux-lts-headers elogind-openrc openrc netifrc grub mkinitcpio archlinux-mirrorlist net-tools rsync nano lsb-release opensysusers opentmpfiles
res=$?; testerror
echo "$YELLOW This is the best part: removing systemd $ALL_OFF"
pacman -Rdd --noconfirm systemd systemd-libs systemd-sysvcompat pacman-mirrorlist dbus
res=$?; testerror

# Previous pacman-mirrorlist removal also deleted this, restoring
cp -vf pacman.d/mirrorlist.artix pacman.d/mirrorlist

echo "$GREEN Installing clean Artix packages $ALL_OFF"
pacman -S --noconfirm --overwrite '*' base base-devel openrc-system linux-lts linux-lts-headers elogind-openrc openrc netifrc grub mkinitcpio archlinux-mirrorlist net-tools rsync nano lsb-release connman opensysusers opentmpfiles
res=$?; testerror
echo "$GREEN Installing service files $ALL_OFF"
pacman -S --noconfirm --needed at-openrc xinetd-openrc cronie-openrc haveged-openrc hdparm-openrc openssh-openrc syslog-ng-openrc connman-openrc
res=$?; testerror

echo "$YELLOW Removing left-over cruft $ALL_OFF"
rm -fv /etc/resolv.conf

echo "$GREEN Enabling basic services $ALL_OFF"
rc-update add haveged sysinit
rc-update add udev sysinit
rc-update add sshd default

echo
echo "$BOLD Activating standard network interface naming (i.e. enp72^7s128%397 --> eth0)."
echo "$BOLD If you prefer the persistent naming, remove the last line from /etc/default/grub"
echo "$BOLD and run $ALL_OFF grub-mkconfig -o /boot/grub/grub.cfg $BOLD when this script prompts for reboot."
echo
echo "Press ENTER $ALL_OFF"
read
echo 'GRUB_CMDLINE_LINUX="net.ifnames=0"' >>/etc/default/grub

pacman -S --needed --noconfirm netifrc
echo "============================="
echo "$BOLD Write down you IP and route.$ALL_OFF"
echo "============================="
ifconfig
route
echo "==============================================================="
echo "$BOLD Press ENTER to edit conf.d/net to configure static networking."
echo "$BOLD No editing is needed if you use dhcp or a network manager, but"
echo "$BOLD you MUST enable the daemon manually BEFORE rebooting.         "
echo "$BOLD You will be given the option at the end of this procedure.    "
echo "$BOLD Default setting is DHCP for eth0, should be enough for most.$ALL_OFF"
echo "==============================================================="
read
nano /etc/conf.d/net
ln -sf /etc/init.d/net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default
res=$?; testerror

# Good riddance
echo "$YELLOW Removing more systemd cruft $ALL_OFF"
for user in journal journal-gateway timesync network bus-proxy journal-remote journal-upload resolve coredump;
  do userdel systemd-$user
done
rm -vfr /{etc,var/lib}/systemd

echo "$GREEN Restoring pacman.conf security settings $ALL_OFF"
sed -i 's/= Never/= Required DatabaseOptional/' /etc/pacman.conf
echo "$GREEN Making OpenRC start faster $ALL_OFF"
sed -i 's/#rc_parallel="NO"/rc_parallel="YES"/' /etc/rc.conf
echo "$GREEN Replacing Arch with Artix in hostname and issue $ALL_OFF"
sed -i 's/Arch/Artix/ig' /etc/hostname /etc/issue 2>/dev/null
echo "$GREEN Recreating initrds $ALL_OFF"
mkinitcpio -P
echo "$GREEN Recreating grub.cfg $ALL_OFF"
cp -vf /boot/grub/grub.cfg /boot/grub/grub.cfg.arch
grub-mkconfig -o /boot/grub/grub.cfg
res=$?; testerror

echo "============================================="
echo "=       If you haven't seen any errors      ="
echo "=            press ENTER to reboot          ="
echo "=   Otherwise switch console and fix them   ="
echo "=                                           ="
echo "=                                           ="
echo "=       Press CTRL-C to stop reboot         ="
echo "=(mandatory if you need a networking daemon)="
echo "=Or switch console/terminal and type as root="
echo "= $BOLD         rc-service add connmand        $ALL_OFF  ="
echo "=    then switch back here and continue     ="
echo "============================================="
read
sync
mount -f / -o remount,ro
echo s >| /proc/sysrq-trigger
echo u >| /proc/sysrq-trigger
echo b >| /proc/sysrq-trigger

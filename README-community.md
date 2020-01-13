# iso-profiles
The Artix ISO profiles

The *community* GTK and Qt profiles (MATE-LXDE-Cinnamon and KDE/Plasma-LXQt) are mostly symlinks to community. Only a few files/directories differ that accomodate settings specific to the flavour. Those files/directories are ***not*** symlinks.

Compared to *base/minimal* profiles, the community profiles differ in:
1. /etc/skel is a lot more populous, as it contains DE and application settings <-- WIP, to be replaced by a package
2. A few scripts in /etc/local.d/ get executed at first boot:
    *    theme-root creates in /root/.config some symlinks to /etc/skel/.config, for allowing sudo apps follow the overall theme, and gets deleted after execution
    *    artix-icons converts all start-here.png icons in /usr/share/icons to the Artix logo
    *    0-remove-openbox-sessions deletes openbox entries in /usr/share/xsessions; openbox sessions are unconfigured and can even hang if chosen. Also gets deleted after execution
    *    change-machine-id replaces machine-id in /etc and /var/lib/dbus at every boot
    *    mkinitcpio detects whether the installation is encrypted or not and modifies /etc/default/grub and /etc/mkinitcpio.conf accordingly
3. The default evowise mirror in mirrorlist-arch is commented out for being very slow
4. rc.local enables the magic sysrq key and replaces the boring /etc/issue with a neofetch dump
5. A nice DIR_COLORS is present in /etc.
6. /etc/environment sets QT_QPA_PLATFORMTHEME=gtk2 and QT_STYLE_OVERRIDE=gtk in the GTK ISO. The other way round in Qt.
7. /etc/vconsole.conf is symlinked to conf.d/consolefont, which is a merge of both. This allows both OpenRC to set the console font and mkinitcpio run the hook early at boot.
8. /etc/xdg/kcm-about-distrorc is branded for Artix (<-- Not needed anymore, Plasma uses lsb-release or something). There are a few more config files there, stolen from other distros.
9. The mkinitcpio.conf in *desktop* profile is preconfigured for rootfs encryption, otherwise system becomes unbootable at first kernel upgrade. If encryption isn't enabled, the script in local.d removes the setting.
10. There's a custom local.bashrc in bashrc/bashrc.d, with a better PS1 and a few useful aliases and customizations. <-- Have been split into 2 packages (2nd is WIP for community)
11. default/grub is preconfigured with the artix-grub-theme and rootfs encryption; see no.9.
12. elogind/logind.conf sets KillUserProcesses=no, which seems to be forgotten to incredibly stupid default 'yes'
13. In profile.d/ libreoffice is themed with SAL_USE_VCLPLUGIN=gtk
14. rc.conf sets *rc_parallel* and *rc_crashed_start* to YES
15. /etc/hosts for live sets *artix* to loopback, some programs hung for a while resolving it
16. The branding icons in /usr/share/icons/matefaenzadark are set to Artix
17. 60-ioschedulers.rules in udev/rules.d sets I/O scheduler according to disk type (ssd/rotational) <-- part of our udev now
18. /root/.config contains settings for Midnight Commander
19. /usr/lib/firefox/distribution/distribution.ini is branded for Artix
20. A little tested and possibly incomplete theme for LXDM lies in /usr/share
21. A tweaked SDDM theme appears in /usr/share/sddm



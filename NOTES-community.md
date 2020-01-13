# Notes

1. buildiso uses /usr/share/artools/pacman-default.conf for all pacman operations, and copies it into the ISO.
2. ~/artools-workspace/iso-profiles overrides the system default ones
3. livefs overlay isn't copied over to installed system
4. having more than one kernel specified in base/Packages-Root fails (June 2019)
5. buildiso seems to use both /etc/pacman.conf and /usr/share/artools/pacman-default.conf


TODO
1. DONE: /etc/default/grub append net.ifnames=0
2. DONE: metalog-openrc instead of syslog-ng-openrc in ~/artools-workspace/iso-profiles/base/Packages-Root, because the latter seems to hang on some systems
3. DONE: connman instead of nm in base/Packages-Live, because it's lighter and just as efficient
4. DONE: gparted instead of partitionmanager
5. DONE: Remove start menu arrow in MATE (~/.config/gtk-3.0/gtk.css)
6. DONE: remove mate-backgrounds and add artix wallpapers instead
7. DONE: Encrypted filesystem requires /crypto_keyfile.bin in mkinitcpio.conf/FILES and cryptkey=rootfs:/crypto_keyfile.bin in default/grub/GRUB_CMDLINE_LINUX, or kernel updates break
8. DONE: For QT ISO: QT_QPA_PLATFORMTHEME must be unset, otherwise icons are invisible in Plasma desktop (nuoveXT2 set gets picked up by the gtk2 settings) and there are dark text on dark background issues in systemsettings5 and some widget settings. QT_STYLE_OVERRIDE=gtk perhaps should be set (e.g. in /etc/environment)
9. DONE: GTK2 toolbar is a png, needs some darkening.

More TODOs, Nov 2019
1. DONE: Virtualbox is ugly with every QT_STYLE_OVERRIDE setting except kvantum-dark; use an alias in /etc/bash/ until fixed upstream
2. DONE: GTK ISO: Use gschema overrides instead of the binary dconf blob <-- almost done, MATE doesn't honour some overrides and we use /etc/dconf instead
3. DONE: Create a basic branding package to keep the profiles lighter.

More TODOs, Jan 2020
3. Create an extended/community branding package.

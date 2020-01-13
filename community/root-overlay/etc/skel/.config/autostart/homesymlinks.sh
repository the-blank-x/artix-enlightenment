#!/bin/sh

cd $HOME
ln -sf .face .face.icon &
ln -sf .gtkrc-2.0 .gtkrc-2.0-kde4 &
rm -f .config/autostart/homesymlinks.* &

#!/bin/bash
# Resize active window to 55% width and center on main screen
# Main screen being defined as the only or the bigger of two screens
# 
# Inspiration: https://10pm.ca/bash-script-to-centre-the-active-window-for-ubuntulinux-mint/
#
# Usage: place in a folder in the PATH (e.g. ~/.local/bin) and bind to a keyboard shortcut
#
# Requirements: 
# - xdotools
# - wmcrtl

NumScreens=$(xrandr --current|grep '*+' | uniq| wc -l)
Xaxis=0
Yaxis=0
XOffset=0
WIDTH=0
HEIGHT=0
if [[ $NumScreens == 2 ]]; then
	echo "two screens";
	XaxisOne=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f1 | head -n 1)
	YaxisOne=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f2 | head -n 1)
	XaxisTwo=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f1 | tail -n 1)
	YaxisTwo=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f2 | tail -n 1)

	if [[ $XaxisOne > $XaxisTwo ]]; then
		Xaxis=${XaxisOne}
		Yaxis=${YaxisOne}
		XOffset=${XaxisTwo}
	else
		Xaxis=${XaxisTwo}
		Yaxis=${YaxisTwo}
		XOffset=${XaxisOne}
	fi;
elif [[ $NumScreens == 1 ]]; then
	echo "one screen";
	Xaxis=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f1)
	Yaxis=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f2)
else
	echo "No support for more than two screens";
	exit;
fi;
WIDTH=$(echo "scale=0;$Xaxis*.55"|bc)
HEIGHT=$Yaxis
X=$(echo "scale=0;$Xaxis/2-$WIDTH/2+$XOffset"|bc)
Y=0
WIN=`xdotool getactivewindow`
echo Resolution: $Xaxis x $Yaxis
echo New dimensions: $WIDTH x $HEIGHT
echo New position: $X x $Y
# unmaximize
wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
xdotool windowmove $WIN $X $Y
xdotool windowsize $WIN $WIDTH $HEIGHT

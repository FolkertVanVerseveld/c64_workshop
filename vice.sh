#!/bin/sh
# Commodore 64 Workshop VICE installation script
#
# Copyright Folkert van Verseveld
# Released under Affero GNU Public License version 3.0 or later
#
# This script fixes common problems while installing VICE on linux.
# Ubuntu for example does not ship the KERNAL ROMS to avoid copyright
# issues even though they are included in the source anyway.
#
# To setup the emulator, you need to run this script as superuser once.
# If the script succeeds, you can start the emulator as a normal user.

EMU=vice-3.1
EMUSRC="$EMU.tar.gz"
EMUDATA="$EMU/data"

# If the script does not work, try to modify these variables
# Your package manager
PKG=apt
# This command will be used to install the package
PKG_INSTALL="$PKG install -y"
# The package name for the emulator
C64PKG=vice
# The emulator command
C64EMU=x64sc
# Command to download documents from the web
CRAWLER=wget
# Command to download the emulator source if necessary
CRAWL_CMD="$CRAWLER -O $EMUSRC"

FIRMWARE_DIR="/usr/lib/vice/"

#######################
# INSTALLATION SCRIPT #
#######################

# Don't modify these:
has_emu=yes
has_luser=no

which "$C64EMU" 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	has_emu=no
fi

if [ "$(id -u)" -ne 0 ]; then
	if [ "$has_emu" = yes ]; then
		"$C64EMU"
		exit $?
	fi
	echo 'This script must be run as root' 1>&2
	exit 1
fi

# Try to figure out the user who started this script
home="$HOME"
if [ "$(echo "$home" | cut -c 1-5)" = "/home" ]; then
	user="$(echo "$home" | cut -c 7-)"
	has_luser=yes
else
	# Either we cannot get the user who started this script
	# or the distro's only user is root.
	echo 'Could not detect user name' 1>&2
	echo 'Emulator will run as root!' 1>&2
fi

which "$PKG" 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	echo 'Could not find your package manager' 1>&2
	exit 1
fi

if [ "$has_emu" = no ]; then
	echo "Installing $C64PKG..."
	$PKG_INSTALL "$C64PKG"
	if [ $? -ne 0 ]; then
		echo 'Could not install the emulator' 1>&2
		exit 1
	fi
fi

which "$C64EMU" 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	echo 'Could not install the emulator' 1>&2
	exit 1
fi

# Try to start emulator and we're done if it works.
# This will fail on Ubuntu because the firmware is missing.
if [ "$has_luser" = yes ]; then
	su -c "$C64EMU" "$user"
else
	"$C64EMU"
fi
if [ $? -eq 0 ]; then
	exit 0
fi

# The real fixing stuff happens here.
# First, we go to /tmp and grab the missing firmware.
# Then we will locate the firmware directory and copy all missing stuff.

# Sanity checks
if [ ! -d "$FIRMWARE_DIR" ]; then
	echo 'Bad firmware directory' 1>&2
	echo "Either create one manually at: $FIRMWARE_DIR" 1>&2
	echo 'or change FIRMWARE_DIR in the script' 1>&2
	exit 1
fi
cd /tmp

which "$CRAWLER" 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	echo 'Could not find your web crawler' 1>&2
	exit 1
fi

$CRAWL_CMD "https://downloads.sourceforge.net/project/vice-emu/releases/$EMUSRC"

tar zxvf "$EMUSRC" && cd "$EMUDATA"
if [ $? -ne 0 ]; then
	echo 'Could not install firmware' 1>&2
	exit 1
fi

cp -a . "$FIRMWARE_DIR"

# Try to start emulator once again.
# If it fails, something else is wrong...
if [ "$has_luser" = yes ]; then
	su -c "$C64EMU" "$user"
else
	"$C64EMU"
fi
if [ $? -ne 0 ]; then
	echo 'Either your environment is broken,' 1>&2
	echo 'or you are using an unsupported system' 1>&2
	exit 1
fi
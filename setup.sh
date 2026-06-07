#!/bin/bash

# Clear Screen
tput reset 2>/dev/null || clear

# Colours (or Colors in en_US)
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NORMAL='\033[0m'

# Abort Function
function abort(){
    [ ! -z "$@" ] && echo -e ${RED}"${@}"${NORMAL}
    exit 1
}

# Banner
function __bannerTop() {
	echo -e \
	${GREEN}"
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
	"${NORMAL}
}

# Welcome Banner
printf "\e[32m" && __bannerTop && printf "\e[0m"

# Minor Sleep
sleep 1

# Determine if sudo is needed and available
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo -e "${RED}Warning: This script must be run as root or with sudo to install system packages.${NORMAL}"
    fi
fi

if [[ "$OSTYPE" == "linux-gnu" || "$OSTYPE" == "linux-musl" ]]; then

    if command -v apt > /dev/null 2>&1; then

        echo -e ${PURPLE}"Ubuntu/Debian Based Distro Detected"${NORMAL}
        sleep 1
        echo -e ${BLUE}">> Updating apt repos..."${NORMAL}
        sleep 1
	    ${SUDO} apt -y update || abort "Setup Failed!"
	    sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1
        ${SUDO} apt install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract device-tree-compiler liblzma-dev python3-pip brotli liblz4-tool axel gawk aria2 detox cpio rename liblz4-dev jq git-lfs rsync neofetch file apktool libarchive-tools || abort "Setup Failed!"

    elif command -v dnf > /dev/null 2>&1; then

        echo -e ${PURPLE}"Fedora Based Distro Detected"${NORMAL}
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

	    # "dnf" automatically updates repos before installing packages
        ${SUDO} dnf install -y unace unrar zip unzip sharutils uudeview arj cabextract file-roller dtc python3-pip brotli axel aria2 detox cpio lz4 python3-devel xz-devel p7zip p7zip-plugins git-lfs || abort "Setup Failed!"

    elif command -v pacman > /dev/null 2>&1; then

        echo -e ${PURPLE}"Arch or Arch Based Distro Detected"${NORMAL}
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

        ${SUDO} pacman -Sy --needed --noconfirm unace unrar p7zip sharutils uudeview arj cabextract file-roller dtc brotli axel gawk aria2 detox cpio lz4 jq git-lfs || abort "Setup Failed!"

    elif command -v apk > /dev/null 2>&1; then

        echo -e ${PURPLE}"Alpine Linux Detected"${NORMAL}
        sleep 1
        echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
        sleep 1
        ${SUDO} apk add --no-cache zip unzip p7zip uudeview arj cabextract dtc brotli lz4 axel gawk aria2 cpio jq git-lfs rsync neofetch file libarchive-tools bash curl python3 py3-pip || abort "Setup Failed!"

    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

    echo -e ${PURPLE}"macOS Detected"${NORMAL}
    sleep 1
	echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	sleep 1
    brew install protobuf xz brotli lz4 aria2 detox coreutils p7zip gawk git-lfs || abort "Setup Failed!"

fi

sleep 1

# Install `uv`
echo -e ${BLUE}">> Installing uv for python packages..."${NORMAL}
sleep 1
if [ -n "$SUDO_USER" ] && command -v sudo >/dev/null 2>&1; then
    sudo -u "$SUDO_USER" bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "Setup Failed!"
else
    bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "Setup Failed!"
fi

# Done!
echo -e ${GREEN}"Setup Complete!"${NORMAL}

# Exit
exit 0

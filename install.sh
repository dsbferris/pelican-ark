#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server

apt -y update
apt -y upgrade
apt -y --no-install-recommends --no-install-suggests install curl lib32gcc-s1 ca-certificates jq

## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

## download and install steamcmd
cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd

mkdir -p /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
tar -xzvf steamcmd.tar.gz -C /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
mkdir -p /mnt/server/steamapps # Fix steamcmd disk write error when this folder is missing
cd /mnt/server/steamcmd

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server

# finish install steamcmd
./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server ${EXTRA_FLAGS} +quit

## set up 32 bit libraries
mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

## set up 64 bit libraries
mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

## create a symbolic link for loading mods
cd /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
ln -sf ../../../../../Steam/steamapps steamapps
cd /mnt/server

# Link the ~20GB ShooterGame/Content folder
if [[ $CONTENT_MOUNT ]]; then
    echo "setup content mount at $CONTENT_MOUNT"
    mkdir -p ShooterGame
    ln -sf "$CONTENT_MOUNT" ShooterGame/Content
fi

rm -f startup.sh
curl -sSLO https://raw.githubusercontent.com/dsbferris/pelican-ark/refs/heads/main/startup.sh \
    && chmod +x startup.sh

curl -sSL -o jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 \
    && chmod +x jq && mv jq /usr/local/bin/

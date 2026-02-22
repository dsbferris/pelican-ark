#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'ubuntu:18.04'
#apt -y update
#apt -y --no-install-recommends --no-install-suggests install curl lib32gcc-s1 ca-certificates

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

## install game using steamcmd
./steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) ${INSTALL_FLAGS} validate +quit


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

# Create .pelicanignore file with default config if it doesnt exist
if [ ! -f ".pelicanignore" ]; then
    echo "Creating .pelicanignore"
    echo "*" > .pelicanignore
    echo "!ShooterGame/Saved/" >> .pelicanignore
fi

# Create whitelist file if it doesnt exist
if [ ! -f "ShooterGame/Binaries/Linux/PlayersJoinNoCheckList.txt" ]; then
    echo "Creating PlayersJoinNoCheckList.txt"
    mkdir -p ShooterGame/Binaries/Linux
    touch -a ShooterGame/Binaries/Linux/PlayersJoinNoCheckList.txt
fi

# Create empty settings files
if [ ! -f "ShooterGame/Saved/Config/LinuxServer/Game.ini" ]; then
    mkdir -p ShooterGame/Saved/Config/LinuxServer
    touch -a ShooterGame/Saved/Config/LinuxServer/Game.ini
fi
if [ ! -f "ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" ]; then
    mkdir -p ShooterGame/Saved/Config/LinuxServer
    touch -a ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
fi


## install end
echo "-----------------------------------------"
echo "Installation completed..."
echo "-----------------------------------------"

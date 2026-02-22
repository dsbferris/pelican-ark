#!/bin/bash

# Graceful stop function: save, exit server, wait for PID, then exit
rmv() {
	echo "stopping server"
	rcon -t rcon -a 127.0.0.1:${RCON_PORT} -p ${ARK_ADMIN_PASSWORD} saveworld \
		&& rcon -t rcon -a 127.0.0.1:${RCON_PORT} -p ${ARK_ADMIN_PASSWORD} DoExit \
		&& wait ${ARK_PID}

	echo "Server Closed"
	exit
}

trap rmv SIGTERM SIGINT

# Move to the server binary directory
cd ShooterGame/Binaries/Linux || exit 1

# Start the ARK server (preserve original argument template and conditional for BattlEye)
./ShooterGameServer ${SERVER_MAP}?listen?SessionName="${SESSION_NAME}"?ServerPassword=${ARK_PASSWORD}?ServerAdminPassword=${ARK_ADMIN_PASSWORD}?Port=${SERVER_PORT}?RCONPort=${RCON_PORT}?QueryPort=${QUERY_PORT}?RCONEnabled=True?MaxPlayers=${MAX_PLAYERS}?GameModIds=${MOD_ID}$( [ "$BATTLE_EYE" == "1" ] || printf %s ' -NoBattlEye' ) -server -automanagedmods ${ARGS} -log &

ARK_PID=$!

# Wait until rcon becomes available before continuing
until
	echo "waiting for rcon connection..."
	(rcon -t rcon -a 127.0.0.1:${RCON_PORT} -p ${ARK_ADMIN_PASSWORD})<&0 & wait $!
do
	sleep 5
done

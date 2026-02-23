#!/usr/bin/env bash

set -o pipefail

echo "####### STARTUP ########"

# Graceful stop function: save, exit server, wait for PID, then exit
rmv() {
    echo "####### STOPPING SERVER ########"
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p "$ARK_ADMIN_PASSWORD" saveworld && \
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p "$ARK_ADMIN_PASSWORD" DoExit && \
    wait "$ARK_PID"
    echo "Server exited gracefully"
    exit 0
}
# SIGINT = 2, SIGTERM = 15
trap rmv SIGTERM SIGINT

# Move to the server binary directory
cd ShooterGame/Binaries/Linux || exit 1

# Build the parameters for the server start command
PARAMS="${SERVER_MAP}?listen?SessionName=\"${SESSION_NAME}\""
PARAMS+="?ServerPassword=${ARK_PASSWORD}?ServerAdminPassword=${ARK_ADMIN_PASSWORD}"
PARAMS+="?Port=${SERVER_PORT}?RCONPort=${RCON_PORT}?QueryPort=${QUERY_PORT}?RCONEnabled=True"
PARAMS+="?MaxPlayers=${MAX_PLAYERS}?GameModIds=${MOD_ID}"
if [ "$BATTLE_EYE" != "1" ]; then
	PARAMS+=" -NoBattlEye"
fi
PARAMS+=" -server -automanagedmods ${ARGS} -log"


echo "####### STARTING SERVER ########"
start=$(date +%s)
./ShooterGameServer $PARAMS &
# Store PID
ARK_PID=$!

sleep 5

counter=0
echo "Waiting for RCON to be available..."
while ! rcon -t rcon -T 1s -a 127.0.0.1:$RCON_PORT -p $ARK_ADMIN_PASSWORD "Broadcast Up'n'running" >/dev/null 2>&1; do
  echo "Server not yet ready... checking again in 5s (retry: $counter)"
  counter=$((counter+1))
  sleep 5
done

end=$(date +%s)
runtime=$((end-start))
echo "Server started successfully in $runtime seconds"

echo "####### RCON CONSOLE ACTIVE ########"
while true; do
    echo "Connecting to RCON Console..."
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p $ARK_ADMIN_PASSWORD
done


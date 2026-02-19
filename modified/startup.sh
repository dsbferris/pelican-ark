#!/bin/bash

# Gracefully stop the ARK server using rcon
rmv() {
    echo "stopping server"
    rcon -t rcon -a "127.0.0.1:${RCON_PORT}" -p "${ARK_ADMIN_PASSWORD}" saveworld \
        && rcon -t rcon -a "127.0.0.1:${RCON_PORT}" -p "${ARK_ADMIN_PASSWORD}" DoExit \
        && wait "${ARK_PID}"

    echo "Server Closed"
    exit
}

# Trap SIGTERM(15) and SIGINT(2) to run cleanup
trap rmv SIGTERM SIGINT

# Move into the server binary directory
cd ShooterGame/Binaries/Linux || { echo "Failed to change directory" >&2; exit 1; }

# Build the server start arguments (template placeholders preserved)
START_ARGS='{{SERVER_MAP}}?listen?SessionName="{{SESSION_NAME}}"?ServerPassword={{ARK_PASSWORD}}?ServerAdminPassword={{ARK_ADMIN_PASSWORD}}?Port={{SERVER_PORT}}?RCONPort={{RCON_PORT}}?QueryPort={{QUERY_PORT}}?RCONEnabled=True?MaxPlayers={{MAX_PLAYERS}}?GameModIds={{MOD_ID}}'
START_ARGS+="$( [ "${BATTLE_EYE:-}" = "1" ] || printf %s ' -NoBattlEye' ) -server -automanagedmods {{ARGS}} -log"

./ShooterGameServer ${START_ARGS} &
ARK_PID=$!

# Wait for rcon to become available
until echo "waiting for rcon connection..."; do
    ( rcon -t rcon -a "127.0.0.1:${RCON_PORT}" -p "${ARK_ADMIN_PASSWORD}" )<&0 & wait $!
    sleep 5
done

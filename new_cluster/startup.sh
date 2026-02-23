#!/usr/bin/env bash

set -o pipefail

echo "####### STARTUP ########"

echo "Checking CONTENT_MOUNT..."
if [[ $CONTENT_MOUNT ]]; then
    if [[ ! -d "$CONTENT_MOUNT" ]]; then
        echo "ERROR: $CONTENT_MOUNT does not exist!"
        exit 1
    fi
fi

# Move to the server binary directory
cd ShooterGame/Binaries/Linux || exit 1

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

get_mods() {
    local COLLECTION_MODS=""
    if [[ $COLLECTION_IDS ]]; then
        IFS=',' read -ra IDS <<< "$COLLECTION_IDS"
        local POST_DATA="collectioncount=${#IDS[@]}"
        for i in "${!IDS[@]}"; do
            POST_DATA+="&publishedfileids[$i]=${IDS[$i]}"
        done

        if COLLECTION_MODS=$(curl -sSL --data "$POST_DATA" https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/ \
            | $HOME/.local/bin/jq -r '.response.collectiondetails[].children[].publishedfileid' \
            | paste -sd "," -) && [[ $COLLECTION_MODS ]]; then
            :
        else
            COLLECTION_MODS=""
        fi
    fi

    local MODS=""
    [[ $COLLECTION_MODS ]] && MODS+="$COLLECTION_MODS"
    [[ $MODS && $MOD_IDS ]] && MODS+=","
    [[ $MOD_IDS ]] && MODS+="$MOD_IDS"

    echo "$MODS"
}

print_mods() {
    # https://steamapi.xpaw.me/#ISteamRemoteStorage/GetPublishedFileDetails
    # https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/?itemcount=2&publishedfileids%5B0%5D=1428596566&publishedfileids%5B1%5D=1404697612
    local MODS=$1
    if [[ $MODS ]]; then
        IFS=',' read -ra MOD_ARRAY <<< "$MODS"
        echo "Mods to be loaded:"
        local POST_DATA="itemcount=${#MOD_ARRAY[@]}"
        for i in "${!MOD_ARRAY[@]}"; do
            POST_DATA+="&publishedfileids[$i]=${MOD_ARRAY[$i]}"
        done

        # Single batched request for all mod IDs
        local RESP=$(curl -sSL --data "$POST_DATA" https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/)

        # Parse and print each returned publishedfiledetails entry
        echo "$RESP" | $HOME/.local/bin/jq -r '.response.publishedfiledetails[] | "\(.title) (ID: \(.publishedfileid))"' | while IFS= read -r line; do
            echo "- $line"
        done
    else
        echo "No mods specified."
    fi
}

echo "Checking for mods..."
MODS=$(get_mods)
print_mods "$MODS"

get_params() {
    # Build the parameters for the server start command
    local PARAMS="$SERVER_MAP?listen"
    PARAMS+="?Port=$SERVER_PORT?QueryPort=$QUERY_PORT?RCONPort=$RCON_PORT?RCONEnabled=True"
    PARAMS+="?MaxPlayers=$MAX_PLAYERS?SessionName=\"$SESSION_NAME\""

    [[ $ARK_PASSWORD ]] && PARAMS+="?ServerPassword=$ARK_PASSWORD"
    [[ $ARK_ADMIN_PASSWORD ]] && PARAMS+="?ServerAdminPassword=$ARK_ADMIN_PASSWORD"
    [[ $ARK_SPECTATOR_PASSWORD ]] && PARAMS+="?SpectatorPassword=$ARK_SPECTATOR_PASSWORD"
    [[ $MODS ]] && PARAMS+="?GameModIds=$MODS"
    [[ $QARGS ]] && PARAMS+="$QARGS"

    PARAMS+=" -server -automanagedmods -log"
    [[ $BATTLE_EYE == 0 ]] && PARAMS+=" -NoBattlEye"
    [[ $WHITELIST == 1 ]] && PARAMS+=" -exclusivejoin"
    [[ $CLUSTER_ID ]] && PARAMS+=" -clusterid=$CLUSTER_ID"
    [[ $CLUSTER_DIR ]] && PARAMS+=" -ClusterDirOverride=$CLUSTER_DIR"
    [[ $ACTIVE_EVENT ]] && PARAMS+=" -ActiveEvent=$ACTIVE_EVENT"
    [[ $ARGS ]] && PARAMS+=" $ARGS"

    echo $PARAMS
}

PARAMS=$(get_params)
echo "Parameters: $PARAMS"

echo "####### STARTING SERVER ########"
start=$(date +%s)
./ShooterGameServer $PARAMS &
# Store PID
ARK_PID=$!

sleep 5
counter=0
echo "Waiting for RCON to be available..."
while ! rcon -t rcon -T 1s -a 127.0.0.1:$RCON_PORT -p $ARK_ADMIN_PASSWORD "Broadcast Hi there" >/dev/null 2>&1; do
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

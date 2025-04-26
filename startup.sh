#!/usr/bin/env bash

set -o pipefail

# Create .pelicanignore file with default config if it doesnt exist
if [ ! -f ".pelicanignore" ]; then
    echo "create .pelicanignore"
    echo "*" > .pelicanignore
    echo "!ShooterGame/Saved/" >> .pelicanignore
fi

# If whitelist enabled create whitelist file if it doesnt exist
if [ $WHITELIST != 0 ]; then
    echo "whitelist enabled"
    mkdir -p ShooterGame/Binaries/Linux;
    touch -a ShooterGame/Binaries/Linux/PlayersJoinNoCheckList.txt
fi

# Link the ~20GB ShooterGame/Content folder
if [[ $CONTENT_MOUNT ]]; then
    if [[ ! -d "$CONTENT_MOUNT" ]]; then
        echo "$CONTENT_MOUNT does not exist!"
        exit 1
    fi
fi


# Function to stop the server
rmv() {
    echo "stopping server"
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p "$ARK_ADMIN_PASSWORD" saveworld && \
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p "$ARK_ADMIN_PASSWORD" DoExit && \
    wait "$ARK_PID"
    echo "Server Closed"
    exit 0
}

# Trap exit signals (SIGTERM and SIGINT)
trap rmv 15 2

# Function to fetch mods
get_mods() {
    COLLECTION_MODS=""
    if [[ $COLLECTION_IDS ]]; then
        IFS=',' read -ra IDS <<< "$COLLECTION_IDS"
        POST_DATA="collectioncount=${#IDS[@]}"
        for i in "${!IDS[@]}"; do
            POST_DATA+="&publishedfileids[$i]=${IDS[$i]}"
        done

        if COLLECTION_MODS=$(curl -sSL --data "$POST_DATA" https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/ \
            | jq -r '.response.collectiondetails[].children[].publishedfileid' \
            | paste -sd "," -) && [[ $COLLECTION_MODS ]]; then
            :
        else
            COLLECTION_MODS=""
        fi
    fi

    MOD_ID=""
    [[ $COLLECTION_MODS ]] && MOD_ID+="$COLLECTION_MODS"
    [[ $MOD_ID && $MOD_IDS ]] && MOD_ID+=","
    [[ $MOD_IDS ]] && MOD_ID+="$MOD_IDS"

    echo "$MOD_ID"
}

get_params() {
    # Get MOD_ID from collections
    echo "$(echo "$MOD_ID" | tr ',' '\n' | wc -l) mods"

    # Build server start params
    PARAMS="$SERVER_MAP?listen?Port=$SERVER_PORT?QueryPort=$QUERY_PORT?RCONPort=$RCON_PORT?RCONEnabled=True"
    PARAMS+="?MaxPlayers=$MAX_PLAYERS?SessionName=\"$SESSION_NAME\""

    [[ $ARK_PASSWORD ]] && PARAMS+="?ServerPassword=$ARK_PASSWORD"
    [[ $ARK_ADMIN_PASSWORD ]] && PARAMS+="?ServerAdminPassword=$ARK_ADMIN_PASSWORD"
    [[ $ARK_SPECTATOR_PASSWORD ]] && PARAMS+="?SpectatorPassword=$ARK_SPECTATOR_PASSWORD"
    [[ $MOD_ID ]] && PARAMS+="?GameModIds=$MOD_ID"
    [[ $QARGS ]] && PARAMS+="$QARGS"

    [[ $BATTLE_EYE == 1 ]] || PARAMS+=" -NoBattlEye"
    PARAMS+=" -server -automanagedmods"
    [[ $CLUSTER_ID ]] && PARAMS+=" -clusterid=$CLUSTER_ID"
    [[ $CLUSTER_DIR ]] && PARAMS+=" -ClusterDirOverride=$CLUSTER_DIR"
    [[ $ACTIVE_EVENT ]] && PARAMS+=" -ActiveEvent=$ACTIVE_EVENT"
    [[ $WHITELIST == 0 ]] || PARAMS+=" -exclusivejoin"
    [[ $ARGS ]] && PARAMS+="$ARGS"
    PARAMS+=" -log"

    echo $PARAMS
}

start=`date +%s`

MOD_ID=$(get_mods)
echo MODS: $MOD_ID

PARAMS=$(get_params)
# echo PARAMS: $PARAMS

# Start the server
cd ShooterGame/Binaries/Linux && ./ShooterGameServer $PARAMS &
# Store PID
ARK_PID=$!

sleep 5

counter=0
echo "Wait for RCON to be available..."
while ! rcon -t rcon -T 1s -a 127.0.0.1:$RCON_PORT -p $ARK_ADMIN_PASSWORD "Broadcast Up'n'running" >/dev/null 2>&1; do
  echo "Server not yet ready... checking again in 5s (retry: $counter)"
  counter=$((counter+1))
  sleep 5
done

end=`date +%s`
runtime=$((end-start))
echo "Server started in $runtime seconds"

while true; do
    echo "Connecting RCON Console"
    rcon -t rcon -a 127.0.0.1:"$RCON_PORT" -p $ARK_ADMIN_PASSWORD
done
# pelican-ark

My modifications to the pelican ASE egg.
Featuring:
- Cluster support
- Share the ~20G ShooterGame/Content between containers with mounts
- Collection_IDS support, not only MOD_IDS
- Refactored startup and install scripts


## jq
format to jq:

jq --indent 4 -r . \
   egg*.json | sponge egg*.json

jq --indent 4 '.scripts.installation.script' -r egg*.json > install.sh

jq --indent 4 --rawfile script install.sh \
   '.scripts.installation.script = $script' \
   egg*.json | sponge egg*.json


jq --indent 4 '.startup_commands.Default' -r egg*.json > startup.sh

jq --indent 4 --rawfile script startup.sh \
   '.startup = $script' \
   egg*.json | sponge egg*.json

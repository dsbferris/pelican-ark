# pelican-ark

### Collections
Base  
https://steamcommunity.com/sharedfiles/filedetails/?id=3470695377

### Mods
https://steamcommunity.com/sharedfiles/filedetails/?id=2962071508
https://steamcommunity.com/sharedfiles/filedetails/?id=3324881669
https://steamcommunity.com/sharedfiles/filedetails/?id=942185438
https://steamcommunity.com/sharedfiles/filedetails/?id=2182894352

2962071508,3324881669,942185438,2182894352

### Startup wrapper
`./startup.sh`

## Ultrawide fix

https://steamcommunity.com/app/346110/discussions/0/1470842897552251265/

In `steamapps\common\ARK\Engine\Config\BaseEngine.ini`  
Search
- `AspectRatioAxisConstraint=AspectRatio_MaintainXFOV`  

Replace
- `AspectRatioAxisConstraint=AspectRatio_MaintainYFOV`
- 

## jq install.sh
jq '.scripts.installation.script' -r egg*.json > install.sh

jq --rawfile script install.sh \
   '.scripts.installation.script = $script' \
   egg*.json \
   > tmp.json && mv tmp.json egg*.json

jq --rawfile script install.sh \
   '.scripts.installation.script = $script' \
   egg*.json | sponge egg*.json

## jq startup.sh
jq '.startup' -r egg*.json > startup.sh

jq --rawfile script startup.sh \
   '.startup = $script' \
   egg*.json \
   > tmp.json && mv tmp.json egg*.json

jq --rawfile script startup.sh \
   '.startup = $script' \
   egg*.json | sponge egg*.json

## jq new startup
jq '.startup_commands.Default' -r egg*.json > startup.sh

jq --rawfile script startup.sh \
   '.startup_commands.Default = $script' \
   egg*.json \
   > tmp.json && mv tmp.json egg*.json

jq --rawfile script startup.sh \
   '.startup_commands.Default = $script' \
   egg*.json | sponge egg*.json

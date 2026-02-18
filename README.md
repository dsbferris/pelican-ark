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
jq '.scripts.installation.script' -r egg-ark-survival-evolved-cluster.json > install.sh

jq --rawfile script install.sh \
   '.scripts.installation.script = $script' \
   egg-ark-survival-evolved-cluster.json \
   > tmp.json && mv tmp.json egg-ark-survival-evolved-cluster.json

jq --rawfile script install.sh \
   '.scripts.installation.script = $script' \
   egg-ark-survival-evolved-cluster.json | sponge egg-ark-survival-evolved-cluster.json

## jq startup.sh
jq '.startup' egg-ark-survival-evolved-cluster.json

jq --rawfile script startup.sh \
   '.startup = $script' \
   egg-ark-survival-evolved-cluster.json \
   > tmp.json && mv tmp.json egg-ark-survival-evolved-cluster.json

jq --rawfile script startup.sh \
   '.startup = $script' \
   egg-ark-survival-evolved-cluster.json | sponge egg-ark-survival-evolved-cluster.json
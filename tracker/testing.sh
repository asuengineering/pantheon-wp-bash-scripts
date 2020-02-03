
# JQ Example
DOMAINS="$(terminus domain:list 2019-engineering.live --fields=id,type,primary --format=json)"
for ITEM in $(jq -c '.[] | [.id,.type,.primary]' <<< "$DOMAINS"); do
    IFS=',' read -r -a ARRAY <<< "$ITEM"
    SITENAME=${ARRAY[0]:2:$((${#ARRAY[0]} - 2 - 1))}
    echo "SiteName: $SITENAME"

    TYPE=${ARRAY[01]:1:$((${#ARRAY[1]} -1 - 1))}
    echo "SiteName: $TYPE"

    PRIMARY=${ARRAY[2]::$((${#ARRAY[2]} - 1))}
    if [[ $PRIMARY == "false" ]]; then
        echo "Liar, liar, pants on fire."
    else
        echo "This is the primary domain."
    fi

    echo "SiteName: $PRIMARY"
done

# TRIAL 1
##################
# DUMPLENGTH=$(jq length return.json)
# DUMPID=$(jq -r .[].id return.json)

# IFS=' ' read -a ARR <<< $DUMPID

# echo $DUMPLENGTH
# echo $DUMPID

# counter=0
# for ITEM in "${ARR[@]}"; do
#   echo "ITEM: $ITEM"
# done
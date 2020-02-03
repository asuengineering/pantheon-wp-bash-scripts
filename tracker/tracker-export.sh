#!/bin/sh
# Script to query multiple sites in Pantheon and gather details about the health and status of our sites.
#   - Gathers details about the container including billing and # of attached domains.
#   - Gather a list of all domains associated with our organization. 
#   TODO: Assess "health" of the site according to several quick-win methods.
#
# Requirements:
#   - Access to Pantheon's terminus CLI
# 
# Inspiration:
#   - Looping logic came from here: https://pantheon.io/docs/backups/#access-backups
# 

# Set output file names.
# Scrupt is set to 'overwrite' existing files, so this will produce one unique file per day.
# To keep all produced files, use an hour:min:sec date element and append it to the file name.
NOW=$(date +"%Y-%m-%d")

# Produce a list of sites for this script to query.
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="fullcircle spoken-word-news acims"

SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
# SITENAMES="fullcircle rossum ssebe-2018 cidse-2019"

# Indicate which environments you want the script to include.
SITEENVS="dev test live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# Preload PLUGREPORT and THEMEREPORT with the correct CSV title rows.
# PANTHEONREPORT="Name,Slug,Created,Framework,Plan,Upstream,Frozen?\n"
# DOMAINREPORT="Name,Domain,Record Type,Recommend Value,Current Value,Status\n"

# ID (id), Name (name), Label (label), Created (created), Framework (framework), Region (region), Organization (organization), Plan (plan_name), Max Multidevs (max_num_cdes), Upstream (upstream), Holder Type (holder_type), Holder ID (holder_id), Owner (owner), Is Frozen? (frozen), Date Last Frozen (last_frozen_at) [default: ""]

# iterate through sites
for thissite in $SITENAMES; do

    # This part of the report can happen prior to the environment loop.
    echo "Issuing terminus commands for: $thissite."

    ## Issue terminus command
    DASHBOARD="$(terminus dashboard:view $thissite --print)"

    ## Issue terminus command
    SITEINFO="$(terminus site:info $thissite --format=csv --fields="id,label,name,created,framework,upstream")"
    
    ## Put results in array. Substitute resulting strings for upstreams with the slugs for the right taxonomy terms.
    linecount=1
    while read -r line; do
        test $linecount -eq 1 && ((linecount=linecount+1)) && continue
        PANUPSTR='"e8fe8550-1ab9-4964-8838-2b9abdccf4bf: https://github.com/pantheon-systems/WordPress"'
        PITCHFORK='"110611cd-f04f-477b-b908-26a162c11c1f: https://github.com/asuengineering/pantheon-upstream-pitchfork.git"'
        FSDT='"54be9969-9f75-4096-927a-ba09f9540c02: https://github.com/asuengineering/pantheon-upstream-fsdt.git"'
        ASUDIVI='"17102044-7ee9-420b-bb32-d8231390e89d: https://github.com/asuengineering/pantheon-upstream-asudivi.git"'
        LABSITE='"ced4d8aa-4315-45ad-9e49-f335b5e9eeba: https://github.com/asuengineering/pantheon-upstream-faculty.git"'
        STATIC='"de858279-cb87-4664-825c-fcb4c2928717: https://github.com/populist/static-html-upstream.git"'
        line=${line//$PANUPSTR/pantheon}
        line=${line//$PITCHFORK/pitchfork}
        line=${line//$FSDT/fsdt}
        line=${line//$ASUDIVI/asu-divi}
        line=${line//$LABSITE/asu-labs}
        line=${line//$STATIC/static-html}

        line=${line//\"/\'}

        IFS=","
        DETAILS=($line)
        unset IFS
    done <<< "$SITEINFO"

    # Look for a property where $DETAILS[0] is set as post-meta.
    PROPERTY="$(10updocker wp post list --post_type=property --meta_value=${DETAILS[0]} --field=ID)"
    
    # Test for empty return
    if [ -z "$PROPERTY" ]; then

        # create the property
        echo "... entry not found. Creating entry for a new property."
        
        PROPERTY="$(10updocker wp post create --post_type=property --post_title="${DETAILS[1]}" --post_name="${DETAILS[2]}" --post_status=pending --post_author=6 --porcelain)"

        ## If we're here, we need to make the UUID field.
        10updocker wp post meta add $PROPERTY '_property_domains|property_url|0|0|value' ${DETAILS[0]} --quiet
        10updocker wp post meta add $PROPERTY '_property_domains|property_url_type|0|0|value' "pantheon-uuid" --quiet

        # iterate through all current site environments
        echo "... pulling information from all Pantheon environments. Might take a few seconds."
        CARBON=1
        ACTIVESITE="sandbox"
        for thisenv in $SITEENVS; do

            ## Get list of domains associated with the properties current environment.
            PROPERTYENV="$(terminus domain:list $thissite.$thisenv --fields=id,type,primary --format=json)"

            for ITEM in $(jq -c '.[] | [.id,.type,.primary]' <<< "$PROPERTYENV"); do
                IFS=',' read -r -a ARRAY <<< "$ITEM"

                DOMAIN=${ARRAY[0]:2:$((${#ARRAY[0]} - 2 - 1))}
                TYPE=${ARRAY[01]:1:$((${#ARRAY[1]} -1 - 1))}
                PRIMARY=${ARRAY[2]::$((${#ARRAY[2]} - 1))}

                ## Platform domains include the direct links to the DEV, TEST and LIVE environments
                if [[ $TYPE == "platform" ]]; then
                    if [[ $thisenv == "dev" ]]; then
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url|$CARBON|0|value" $DOMAIN --quiet
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url_type|$CARBON|0|value" "pantheon-dev" --quiet
                        CARBON=$((CARBON+1))
                        echo "... added Pantheon DEV link."
                    elif [[ $thisenv == "test" ]]; then
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url|$CARBON|0|value" $DOMAIN --quiet
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url_type|$CARBON|0|value" "pantheon-test" --quiet
                        CARBON=$((CARBON+1))
                        echo "... added Pantheon TEST link."
                    elif [[ $thisenv == "live" ]]; then
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url|$CARBON|0|value" $DOMAIN --quiet
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url_type|$CARBON|0|value" "pantheon-live" --quiet
                        CARBON=$((CARBON+1))
                        echo "... added Pantheon LIVE link."
                    fi

                ## Any other domain that we care about should be of the type "custom"
                elif [[ $TYPE == "custom" ]]; then

                    ## If there is any kind of custom domain on the account, the billing must be on in Pantheon.
                    ## Therefore we'll mark it as an "active" site.

                    ACTIVESITE="active"

                    if [[ $PRIMARY == "true" ]]; then
                        echo "... primary domain found."
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url|$CARBON|0|value" $DOMAIN --quiet
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url_type|$CARBON|0|value" "primary-url" --quiet
                        CARBON=$((CARBON+1))
                        
                    elif [[ $PRIMARY == "false" ]]; then
                        echo "... additional domain found."
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url|$CARBON|0|value" $DOMAIN --quiet
                        10updocker wp post meta add $PROPERTY "_property_domains|property_url_type|$CARBON|0|value" "alternate-url" --quiet
                        CARBON=$((CARBON+1))
                    fi

                fi

            done

        done

        # create additional post meta entries
        10updocker wp post meta add $PROPERTY "_property_request_date" $NOW --quiet
        10updocker wp post meta add $PROPERTY "_property_launch_date" $NOW --quiet

        # create the taxonomy entries

        10updocker wp post term add $PROPERTY "hosting" "pantheon" --quiet
        10updocker wp post term add $PROPERTY "technology" "wordpress" --quiet
        10updocker wp post term add $PROPERTY "technology" ${DETAILS[5]} --quiet
        
        # Based on returned results from domains retreived above, either tag as sandbox or active
        10updocker wp post term add $PROPERTY "property-status" $ACTIVESITE --quiet
    
    else
        echo "... entry found. Skipping for now."
        # TODO: Update the existing property info with just a few details. Takes less time.

    fi

    echo "... done with $thissite.\n"

done
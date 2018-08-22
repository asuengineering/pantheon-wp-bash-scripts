#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Grabs site list from Pantheon and loops through sites based on that.

# Produce a list of sites for this script to query.
#  - Use site:list to produce a list for a specific team, owner, or REGEX name expression.
#  - Use org:site:list for filtering sites within an organization by a tag from the dashboard.
#  - Create a space separated list of sites if neither of these options will work for you.
# 
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="nanophotonics nestt"

SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

# The easiest way to get the info here is to declare it.
# To prevent the script from deploying to the live site, omit "live" from the list below.
SITEENVS="dev test live"

# iterate through sites
for thissite in $SITENAMES; do

    # Flag to decide whether an update was applied to a site. Useful later.
    UPDATEFLAG=false

    # check for upstream updates
    echo -e "\nSITE: $thissite"
    
    FRAMEWORK="$(terminus site:info $thissite --field="framework")"
    if [[ $FRAMEWORK != "wordpress" ]]; then
        echo -e "... this isn't WordPress. Let's skip it."
        continue
    fi

    for thisenv in $SITEENVS; do

        if [[ "$thisenv" == "dev" ]]; then
            UPSTREAM_UPDATES="$(terminus upstream:updates:status $thissite.$thisenv)"

            if [[ "$UPSTREAM_UPDATES" == "current" ]]; then
                # no upstream updates available
                echo -e "...no upstream updates found for the $thisenv environment."
        
            elif [[ "$UPSTREAM_UPDATES" == "outdated" ]]; then
                echo -e "...updates are available. Pushing updates to the $thisenv environment."

                UPDATEFLAG=true

                # Checks for Git Mode, quietly.
                terminus connection:set $thissite.$thisenv git -q

                # Apply upstream updates
                terminus upstream:updates:apply $thissite.$thisenv --yes --updatedb --accept-upstream

                # Create backups for live version of the site.
                echo -e "...doing the sensible thing & creating a backup of the live environment first."
                terminus backup:create $site_name.live --element="all" -q
        
            elif [ -n "$UPSTREAMUPDATES" ]; then
                echo -e "...Terminus wasn't sure if updates should be applied or not."
                echo -e "...you might want to go check out the site's dashboard manually."
                terminus dashboard.view $thissite.$thisenv
                continue
            fi
        
        elif [[ "$thisenv" == "test" ]] || [[ "$thisenv" == "live" ]]; then

            echo -e "...deploying code to the $thisenv environment."
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

        fi
    
    done

    if [ "$UPDATEFLAG" = true ]; then
        echo -e "...no automated testing was done on SITE: $thissite."
        echo -e "...instead, opening in a browser for human eyeball testing."
        terminus env:view $thissite.live
    fi
    
    echo -e "Work complete with SITE: $thissite"

done

echo -e "Script complete."

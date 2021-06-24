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
# SITENAMES="customize-static additive-manufacturing"

SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

# The easiest way to get the info here is to declare it.
# To prevent the script from deploying to the live site, omit "live" from the list below.
SITEENVS="live"

# iterate through sites
for thissite in $SITENAMES; do

    # Flag to decide whether an update was applied to a site. Useful later.
    UPDATEFLAG="current"

    # check for upstream updates
    echo -e "\nSITE: $thissite"
    
    # Returns a string. The string may or may not start with a "1" (false converted to string).
    # If it starts with a 1 (string=false), it's frozen.
    # If it doesn't contain WordPress, then we can safely skip it.
    FRAMEWORK="$(terminus site:info $thissite --fields="frozen,framework" --format=string)"
    
    if [[ $FRAMEWORK != *"wordpress"* ]]; then
        echo -e "... this isn't WordPress. Skipping it."
        continue
    fi

    if [[ $FRAMEWORK == *"1"* ]]; then
        echo "... this site is frozen. Skipping it."
        continue
    fi

    for thisenv in $SITEENVS; do

        if [[ "$thisenv" == "live" ]]; then

            echo -e "...checking for updates in the $thisenv environment."
            UPDATEFLAG="$(terminus upstream:updates:status $thissite.$thisenv)"

            if [ "$UPDATEFLAG" == "outdated" ]; then

                echo -e "...doing the sensible thing & creating a backup of the code and db first."
                terminus backup:create $thissite.$thisenv --element="code" -q
                terminus backup:create $thissite.$thisenv --element="db" -q

                echo -e "...deploying code to the $thisenv environment."
                terminus env:deploy $thissite.$thisenv --sync-content --note="Updates deployed via automated bash script."

                echo -e "...clearing the cache for the site."
                terminus env:clear-cache $thissite.$thisenv
            
            fi

        fi
    
    done

    if [ "$UPDATEFLAG" == "outdated" ]; then
        echo -e "...no automated testing was done on SITE: $thissite."
        echo -e "...instead, opening in a browser for human eyeball testing."
        terminus env:view $thissite.live
    fi
    
    echo -e "Work complete with SITE: $thissite"

done

echo -e "Script complete."

#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Grabs site list from Pantheon and loops through sites based on that.

# Update sequence for June 29, 2018
# Applies upstream updates to all sites and all major environments. (Excludes multi-dev.)
# Upstream updates will include the deployment of a hotfix MU plugin that patches a vulnerability in WP Core.
# Conducts search-replace on LIVE database to replace old Instagram handle with the new one.


SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
## SITENAMES="labelle-lab"
SITEENVS="dev test live"

# iterate through sites
SITECOUNT=($SITENAMES)
echo -e "Applying upstream code changes and Instagram fixes for ${#SITECOUNT[@]} sites.\n"
SITENUM=0
for thissite in $SITENAMES; do

    # Flag to decide whether an update was applied to a site. Useful later.
    UPDATEFLAG=false
    SITENUM=$[SITENUM + 1]
    # check for upstream updates
    echo -e "Working with site $SITENUM of ${#SITECOUNT[@]}: $thissite"
    
    FRAMEWORK="$(terminus site:info $thissite --field="framework")"
    if [[ $FRAMEWORK != "wordpress" ]]; then
        echo -e "... this isn't WordPress. Let's skip it."
        continue
    fi

    for thisenv in $SITEENVS; do

        if [[ "$thisenv" == "dev" ]]; then

            echo -e "... applying Instagram handle DB fix to the $thisenv environment."
            terminus connection:set $thissite.$thisenv sftp -q
            terminus wp $thissite.$thisenv -- search-replace instagram.com/fultonengineering instagram.com/asuengineering
            terminus wp $thissite.$thisenv -- search-replace engineering.asu.edu/factbook/why-students-choose-fulton-engineering engineering.asu.edu/about
            terminus wp $thissite.$thisenv -- search-replace engineering.asu.edu/factbook/data engineering.asu.edu/enrollment
            terminus wp $thissite.$thisenv -- search-replace factbook.engineering.asu.edu/about/the-fulton-difference engineering.asu.edu/about

            # Check the site for updates present, and attempt to apply them normally.
            UPDATEAVAIL="$(terminus upstream:updates:status $thissite.$thisenv)"
            if [[ "$UPDATEAVAIL" == "outdated" ]]; then

                echo "... updates are available."

                # Create backup for live version of the site.
                echo -e "... creating a backup of the code base & database for the live environment."
                terminus backup:create $thissite.live --element="code" -q
                terminus backup:create $thissite.live --element="db" -q

                echo "... switching to git mode, attempting to apply updates."
                terminus connection:set $thissite.$thisenv git -q
                terminus upstream:updates:apply $thissite.$thisenv --yes --accept-upstream -q
                
                # test again to see if it worked.
                UPDATEAPPLIED="$(terminus upstream:updates:status $thissite.$thisenv)"
                if [[ "$UPDATEAPPLIED" == "current" ]]; then
                    echo "... updates applied to site normally."
                    UPDATEFLAG=true
                elif [[ "$UPDATEAPPLIED" == "outdated" ]]; then
                    # Merge conficts exist. Recommend manual GIT merge conflict resolution.
                    echo "... a merge confict exists with the site's codebase. Automatically accepting the upstream didn't work."
                    echo "... resolve the conflict manually or run a different script to automatically update in favor of the upstream."
                fi

            elif [[ "$UPDATEAVAIL" == "current" ]]; then
                echo "... no upstream updates found."
                continue
            fi
        
        elif [[ "$thisenv" == "test" ]] || [[ "$thisenv" == "live" ]]; then

            echo -e "... attempting to deploy code to the $thisenv environment."
            terminus connection:set $thissite.$thisenv git -q
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

            echo -e "... applying DB changes including Instagram handle switch to the $thisenv environment."
            terminus connection:set $thissite.$thisenv sftp -q
            terminus wp $thissite.$thisenv -- search-replace instagram.com/fultonengineering instagram.com/asuengineering --quiet
            terminus wp $thissite.$thisenv -- search-replace engineering.asu.edu/factbook/why-students-choose-fulton-engineering engineering.asu.edu/about --quiet
            terminus wp $thissite.$thisenv -- search-replace engineering.asu.edu/factbook/data engineering.asu.edu/enrollment --quiet
            terminus wp $thissite.$thisenv -- search-replace factbook.engineering.asu.edu/about/the-fulton-difference engineering.asu.edu/about --quiet
            terminus connection:set $thissite.$thisenv git -q
        fi
    
    done
    
    echo -e "Work complete with $thissite.\n"

done

echo -e "Script complete."

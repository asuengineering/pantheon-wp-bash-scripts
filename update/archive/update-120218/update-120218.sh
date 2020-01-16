#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Grabs site list from Pantheon and loops through sites based on that.

# Update sequence for Dec 2, 2018
# Applies upstream updates to all sites and all major environments. (Excludes multi-dev.)
# Straightforward application of plugin updates to sites. 


## SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
## SITENAMES="labelle-lab"
SITENAMES="additive-manufacturing advising-directory lab-pavements e2camp fso-cbbg next-steps lab-newt lab-dream fse-volunteer hiring explore fse-tour nerd-herd fse-communications customize"
SITEENVS="dev test live"

# iterate through sites
SITECOUNT=($SITENAMES)
echo -e "Applying upstream code changes for ${#SITECOUNT[@]} sites.\n"
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
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

        fi
    
    done
    
    echo -e "...no automated testing was done on SITE: $thissite."
    echo -e "...instead, opening in a browser for human eyeball testing."
    terminus env:view $thissite.live 
    echo -e "Work complete with $thissite.\n"

done

echo -e "Script complete."

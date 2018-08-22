#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Grabs site list from Pantheon and loops through sites based on that.

# Third iteration of this script.
# Adds Automatic GIT Upstream resolution to the actions taken to push updates through.

## SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
SITENAMES="fulton-student-council fse-scholarships sierks-lab customize"
SITEENVS="dev test live"

# iterate through sites
SITECOUNT=($SITENAMES)
echo "Applying upstream changes for ${#SITECOUNT[@]} sites.\n"
SITENUM=0
for thissite in $SITENAMES; do

    # Flag to decide whether an update was applied to a site. Useful later.
    UPDATEFLAG=false
    SITENUM=$[SITENUM + 1]
    # check for upstream updates
    echo "Working with site $SITENUM of ${#SITECOUNT[@]}: $thissite"
    
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
                echo -e "... creating a backup of the code base for all standard environments first."
                terminus backup:create $thissite.dev --element="code" -q
                terminus backup:create $thissite.test --element="code" -q
                terminus backup:create $thissite.live --element="code" -q

                echo "... switching to git mode, attempting to apply updates."
                terminus connection:set $thissite.$thisenv git -q
                terminus upstream:updates:apply $thissite.$thisenv --yes --accept-upstream -q
                
                # test again to see if it worked.
                UPDATEAPPLIED="$(terminus upstream:updates:status $thissite.$thisenv)"
                if [[ "$UPDATEAPPLIED" == "current" ]]; then
                    echo "... updates applied to site normally."
                elif [[ "$UPDATEAPPLIED" == "outdated" ]]; then
                    # Merge conficts exist. Here's how we deal with them.
                    echo "... a merge confict exists with the site's codebase. Automatically accepting the upstream didn't work."
                    echo "... running git commands to manually resolve the problem in favor of the site's upstream."
                    GITURL="$(terminus connection:info $thissite.dev --field=git_url)"
                    git clone $GITURL workingfolder -q
                    cd workingfolder
                    echo "... adding upstream, resolving conflicted state."
                    UPSTREAM="$(terminus site:info $thissite --field=upstream)"
                    UPSTREAMURL=$(echo $UPSTREAM| cut -d' ' -f 2)
                    git remote add upstream $UPSTREAMURL
                    git pull -X theirs upstream master > /dev/null
                    grep -lr '<<<<<<<' . | xargs git checkout -q --theirs
                
                    echo "... conflict resolved. Commiting code to repository."
                    git commit -am "Resolving merge conflict with upstream repository." -q
                    git push -q

                    echo "... cleaning up working folder."
                    cd ..
                    rm -rf workingfolder
                fi
                
                UPDATEFLAG=true

            elif [[ "$UPDATEAVAIL" == "current" ]]; then
                echo "... no upstream updates found."
                continue
            fi
        
        elif [[ "$thisenv" == "test" ]] || [[ "$thisenv" == "live" ]]; then

            echo -e "... attempting to deploy code to the $thisenv environment."
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

        fi
    
    done
    
    echo -e "Work complete with $thissite.\n"

done

echo -e "Script complete."

#!/bin/sh
# Script to loop through multiple sites to resolve a merge conflict introduced to an upstream repo.

# We need to start with a list of sites for this script to query. They should all belong to the same upstream
# But, currently, there's no terminus command to list sites belonging to a particular upstream.
# So, we'll get the names outside of this script and work accordingly.
# SITENAMES="fullcircle spoken-word-news acims"

SITENAMES="events-guide fse-homecoming labelle-lab e2camp"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
echo "Resolving merge conflicts for ${#SITECOUNT[@]} sites.\n"
SITENUM=0
# iterate through sites
for thissite in $SITENAMES; do
    SITENUM=$[SITENUM + 1]
    echo "Working with site $SITENUM of ${#SITECOUNT[@]}: $thissite"

    # Check the site for updates present, and attempt to apply them normally.
    UPDATEFAIL=false
    UPDATEAVAIL="$(terminus upstream:updates:status $thissite.dev)"
    if [[ ${UPDATEAVAIL} == "outdated" ]]
    then
        echo "... switching to git mode, attempting to apply updates."
        terminus connection:set $thissite.dev git -q
        terminus upstream:updates:apply $thissite.dev -q
        
        # test again to see if it worked.
        UPDATEAPPLIED="$(terminus upstream:updates:status $thissite.dev)"
        if [[ ${UPDATEAPPLIED} == "current" ]]
        then
            echo "... updates applied to site normally."
        else
            # Merge conficts exist.
            UPDATEFAIL=true
        fi
    else
        echo "... no upstream updates found."
    fi

    if [ "$UPDATEFAIL" = true ]
    then
        echo "... merge confict exists in site. Attempting to resolve."
        GITURL="$(terminus connection:info $thissite.dev --field=git_url)"
        git clone $GITURL workingfolder -q
        cd workingfolder
        echo "... adding upstream, resolving conflicted state."
        git remote add fsdt-upstream https://github.com/asuengineering/pantheon-upstream-fsdt.git
        git pull -q -X theirs fsdt-upstream master
        grep -lr '<<<<<<<' . | xargs git checkout -q --theirs
    
        echo "... conflict resolved. Pushing code up to DEV."
        git commit -am "Resolving merge conflict with new upstream repository." -q
        git push -q

        echo "... cleaning up."
        cd ..
        rm -rf workingfolder
    fi

    echo "Work completed with $thissite.\n"

done
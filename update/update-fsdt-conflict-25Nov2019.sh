#!/bin/sh
# Script to loop through multiple sites to resolve a merge conflict introduced to an upstream repo.

# We need to start with a list of sites for this script to query. They should all belong to the same upstream
# But, currently, there's no terminus command to list sites belonging to a particular upstream.
# So, we'll get the names outside of this script and work accordingly.
# SITENAMES="fullcircle spoken-word-news acims"

# SITENAMES="$(terminus site:list --upstream=54be9969-9f75-4096-927a-ba09f9540c02 --field="name" --format="list")"
SITENAMES="acims fse-scholarships customize edo-resources nasa-space-grant-robotics kannan-lab xiangfan-chen nik-chawla acharya engineering-futures cen global-center-for-safety-initiative lab-adapt fac-kodibagkarlab asu-mbe transfer pavements-summit em-symposium cooperative-robotics zhuang mctb-symposium sun-devil-racing-development asu-industrial-assessment-center progressive-learning-platform stabenfeldt-lab plaisierlab rossum lab-anamitra-pal fac-azeredo 3d-print-lab asce mascaro allee-group angelia sarma-iot fac-ruben-acuna blockchain-research young-engineers air-devils society-women-engineers ewb ieee kyle-squires bmes hkn fulton-outreach fac-yezhou-yang nerd-herd ls2016 mav sdsl lab-aims maes sase lak19 fac-yan-chen awic sun-devil-robotics nannenga engineering-technical-services lab-hildreth fac-javier-gonzalez-sanchez sops lw2017 fulton-student-council sierks-lab"

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
        git commit -am "Resolving merge conflict, aligning code with upstream repository." -q
        git push -q

        echo "... cleaning up."
        cd ..
        rm -rf workingfolder

        echo "... making a backup, cloning site from LIVE to DEV."
        terminus backup:create $thissite.dev --element="db" -q
        terminus env:clone-content $thissite.live dev -q
        terminus env:clear-cache $thissite.dev -q

        echo "... human eyeball testing, please."
        terminus env:view $thissite.dev
    fi

    echo "Work completed with $thissite.\n"

done
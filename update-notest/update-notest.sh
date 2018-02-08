#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Assumes a CSV exists with 5 columns of data in order listed below


# Name the target CSV for this document
# Output from another script: 
# INPUT="../sitelists/pantheon_test.csv"

INPUT="../sitelists/pantheon_all.csv"
MULTIDEV=upstream-up

# Keep track of the Internal File Sperator token to whatever it is before we run the script
# Change the Internal File Sperator token to a comma for our CSV
OLDIFS=$IFS
IFS=,

# Check if the input file exists and kill the script if not
[[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }

#  while in this loop, parse the columns in the CSV as these variables
# 	sitename        = name of site (slug) in Pantheon
#   id              = EEID of each site
# 	created         = "2017-03-06 22:05:49"
# 	service_level   = personal, professional, sandbox
# 	framework       = wordpress, drupal, unknown
# 	owner           = EEID of the owner of each site. In our case, we'll likely not use this but it's EOD/EOL protection.

# To jump over the first line in the CSV, we need a counter variable. Output from terminus includes a title row.
echo -e "Importing list of sites to be updated. Processing the title row."
i=1
while read site_name id created service_level framework owner
do
    # skip first line, otherwise increment counter
    test $i -eq 1 && ((i=i+1)) && continue

    # check for upstream updates
    echo -e "\nSITE: $site_name"
    
    if [[ "$framework" != "wordpress" ]]; then
        echo -e "... this isn't WordPress. Let's skip it."
        continue
    fi

    # Checking for updates
    # First, check the DEV environment
    ENVLOOP=('dev' 'test' 'live')
    for ENV in "${ENVLOOP[@]}"; do

        if [[ "$ENV" == "dev" ]]; then
            UPSTREAM_UPDATES="$(terminus upstream:updates:status $site_name.$ENV)"

            if [[ "$UPSTREAM_UPDATES" == "current" ]]; then
                # no upstream updates available
                echo -e "...no upstream updates found for the $ENV environment."
        
            elif [[ "$UPSTREAM_UPDATES" == "outdated" ]]; then
                echo -e "...updates are available. Pushing updates to the $ENV branch."
            
                # Checks for Git Mode, quietly.
                terminus connection:set $site_name.$ENV git -q

                # Apply upstream updates
                terminus upstream:updates:apply $site_name.$ENV --yes --updatedb --accept-upstream

                # Create backups for live version of the site.
                # Logic here is that code already applied and sitting in various environments is likely OK.
                # But, code applied for the first time into the DEV environment is potentially breaking things.
                # echo -e "...doing the sensible thing & creating a backup of the live environment first."
                # terminus backup:create $site_name.live --element="all" -q
        
            elif [ -n "$UPSTREAMUPDATES" ]; then
                echo -e "...Terminus wasn't sure if updates should be applied or not."
                echo -e "...you might want to go check out the site's dashboard manually."
                terminus dashboard.view $site_name.$ENV
                continue
            fi
        
        elif [[ "$ENV" == "test" ]] || [[ "$ENV" == "live" ]]; then

            echo -e "...deploying code to the $ENV environment."
            terminus env:deploy $site_name.$ENV --sync-content --cc --note="Updates deployed via automated bash script."

        fi
    
    done

    echo -e "Work complete with SITE: $site_name"
    terminus env:view $site_name.live
    # TODO: Open browser only if there was an actual update applied.

# if we are not at the end of the file, we are not done, loop again
done < $INPUT

echo -e "Script complete."

# after the loop, reset the Internal File Sperator to whatever it was before
IFS=$OLDIFS

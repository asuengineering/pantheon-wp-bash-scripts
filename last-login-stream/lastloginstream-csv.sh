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
LOGINFILE="loginreport-$NOW.csv"

# Produce a list of sites for this script to query.
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
# SITENAMES="acharya fullcircle"

SITENAMES="$(terminus org:site:list asu-engineering --upstream=54be9969-9f75-4096-927a-ba09f9540c02 --field=name)"

# Indicate which environments you want the script to include.
SITEENVS="live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# Preload PLUGREPORT and THEMEREPORT with the correct CSV title rows.
LOGINREPORT="Slug,Environment,Date,UserRole,Summary\n"

# iterate through sites
for thissite in $SITENAMES; do

    # This part of the report can happen prior to the environment loop.
    echo "Issuing terminus commands for: $thissite."

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... getting login info associated with this site's $thisenv environment."

        LINELABEL="$thissite,$thisenv"
        LOGININFO="$(terminus wp $thissite.$thisenv -- stream query --action=login --format=csv --records_per_page=1 --fields=created,user_role,summary)"

        # LOGININFO works with multiple records per site as well, if a more robust report is wanted.
        
        while read -r line; do
            LOGINREPORT+="$LINELABEL,$line\n"
        done <<< "$LOGININFO"

    done

    echo "... done with $thissite.\n"

done

# Append the data to a file.
# File operations here as well - check to see if the file exists, delete it, etc. 

echo "Generating login report."

# Make the files first if they don't exist.
if [ -f "$LOGINFILE" ]; then touch $LOGINFILE; fi

# Write/overwrite data to the files.
echo "$LOGINREPORT" > "$LOGINFILE"
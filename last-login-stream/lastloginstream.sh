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
LASTLOGIN="lastlogin-$NOW.txt"

# Make the files first if they don't exist.
if [ -f "$LASTLOGIN" ]; then touch $LASTLOGIN; fi

# Produce a list of sites for this script to query.
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --upstream=54be9969-9f75-4096-927a-ba09f9540c02 --field=name)"
# SITENAMES="3d-print-lab fullcircle acims"

SITENAMES="$(terminus org:site:list asu-engineering --upstream=54be9969-9f75-4096-927a-ba09f9540c02 --field=name)"

# Indicate which environments you want the script to include.
SITEENVS="live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# iterate through sites
for thissite in $SITENAMES; do

    # This part of the report can happen prior to the environment loop.
    echo "Issuing terminus commands for: $thissite."

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... getting domain info associated with this site's $thisenv environment."

        LOGIN="$(terminus wp $thissite.$thisenv -- stream query --action=login)"

        SLUG="Site: $thissite"

        echo "Site: $thissite" >> "$LASTLOGIN"
        echo "Environment: $thisenv" >> "$LASTLOGIN"
        echo "$LOGIN" >> "$LASTLOGIN"

    done

    echo "... done with $thissite.\n"

done

echo "Report generated."

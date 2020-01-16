#!/bin/sh
# Script to query multiple sites in Pantheon and perform a few WP-CLI commands against all of them.
#   - Gathers a plugin list for all sites/environments and creates one big CSV file for them.
#   - Gathers the active theme for all sites and compiles that list as well. Exports CSV.
#   - Gather a list of all registered users for any site polled. Limited to LIVE sites. Exports CSV.
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
PLUGFILE="pluginreport-$NOW.csv"
THEMEFILE="themereport-$NOW.csv"
USERFILE="userreport-$NOW.csv"

# Produce a list of sites for this script to query.
#  - Use site:list to produce a list for a specific team, owner, or REGEX name expression.
#  - Use org:site:list for filtering sites within an organization by a tag from the dashboard.
#  - Create a space separated list of sites if neither of these options will work for you.
# 
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="site1 site2 site3"

SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

# Indicate which environments you want the script to include.
# TODO: 
#  - Doing something like terminus env:list $thissite --field="id" --format="list"
#  - could create an additional loop that could catch multidev environments + dev/test/live.
#  - also avoids errors due to environments not being initialized yet.

SITEENVS="live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# Preload PLUGREPORT and THEMEREPORT with the correct CSV title rows.
PLUGREPORT="site,environment,plugin-name,status,update,version\n"
THEMEREPORT="site,environment,theme-name,status,update,version\n"
USERREPORT="site,environment,ID,login,display-name,email,register-date,roles\n"

# iterate through sites
for thissite in $SITENAMES; do

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... issuing WP-CLI commands for: $thissite.$thisenv"

        # Terminus "pipe" command to query an individial site via WP-CLI
        # The 2>/dev/null part supresses any notices or warnings that comes from the command.
        # Plugins:
        SITEPLUGS="$(terminus wp $thissite.$thisenv -y -v -- plugin list --format=csv 2>/dev/null)"
        
        # CSV output from terminus includes a title row, which we'll need to replace eventually.
        # We'll identify the first row with a counter variable and exclude it from the output.
        linecount=1

        # Read lines from report, skip title row and append content to variable.
        # In addition to the CSV output from the WP-CLI command, we'll add the Pantheon site name and environment.
        while read -r line; do
            test $linecount -eq 1 && ((linecount=linecount+1)) && continue
            PLUGREPORT+="$thissite,$thisenv,$line\n"
        done <<< "$SITEPLUGS"

        # Themes. Same exact loop as before. Append site name + site environment to output from command.
        SITETHEMES="$(terminus wp $thissite.$thisenv -y -v -- theme list --format=csv 2>/dev/null)"
        linecount=1
        while read -r line; do  
            test $linecount -eq 1 && ((linecount=linecount+1)) && continue   
            THEMEREPORT+="$thissite,$thisenv,$line\n"
        done <<< "$SITETHEMES"

        # Users. Same as before.
        if [[ "$thisenv" = "live" ]]; then
            SITEUSERS="$(terminus wp $thissite.$thisenv -y -v -- user list --format=csv 2>/dev/null)"
            linecount=1
            while read -r line; do  
                test $linecount -eq 1 && ((linecount=linecount+1)) && continue   
                USERREPORT+="$thissite,$thisenv,$line\n"
            done <<< "$SITEUSERS"
        fi

    done

done

# Append the data to a file.
# File operations here as well - check to see if the file exists, delete it, etc. 

echo "Generating plugin, theme and users lists."

# Make the files first if they don't exist.
if [ -f "$PLUGFILE" ]; then touch $PLUGFILE; fi
if [ -f "$THEMEFILE" ]; then touch $THEMEFILE; fi
if [ -f "$USERFILE" ]; then touch $USERFILE; fi

# Write/overwrite data to the files.
echo "$PLUGREPORT" > "$PLUGFILE"
echo "$THEMEREPORT" > "$THEMEFILE"
echo "$USERREPORT" > "$USERFILE"
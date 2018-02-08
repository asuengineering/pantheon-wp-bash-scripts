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
PANTHEONFILE="pantheonreport-$NOW.csv"
DOMAINFILE="domainreport-$NOW.csv"


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

SITEENVS="dev test live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# Preload PLUGREPORT and THEMEREPORT with the correct CSV title rows.
PANTHEONREPORT="site,environment,plugin-name,status,update,version\n"
PANTHEONREPORT="Name,Created,Framework,Service Level,Upstream,PHP Version\n"

# This part of the report can happen prior to the environment loop.
echo "... issuing terminus commands for: $thissite."
SITEINFO="$(terminus site:info $thissite --format=csv --fields="name,created,framework,service_level,upstream,php_version")"

SITEREPORT+="$thissite,"
# Read lines from output and convert/format as needed. Line count used here to format specific parts of the returned list.
# Better idea: search-replace part of the string with the correct results?
linecount=1
while read -r line; do
    DATA=$line
    test $linecount -eq 5 && ((DATA="UpstreamID"))
    SITEREPORT
    linecount=linecount+1
    SITEREPORT+="$DATA,"
done <<< "$SITEINFO"

# iterate through sites
for thissite in $SITENAMES; do

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... issuing terminus commands for: $thissite.$thisenv"

        SITEPLUGS="$(terminus site:info $thissite --format=csv --fields="name,created,service_level,upstream,php_version")"
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
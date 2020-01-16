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
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="fullcircle spoken-word-news acims"

SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

# Indicate which environments you want the script to include.
SITEENVS="live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)
echo "Getting information about ${#SITECOUNT[@]} sites and ${#SITEENVCOUNT[@]} environments."

# Preload PLUGREPORT and THEMEREPORT with the correct CSV title rows.
PANTHEONREPORT="Name,Slug,Created,Framework,Plan,Upstream,Frozen?\n"
DOMAINREPORT="Name,Domain,Record Type,Recommend Value,Current Value,Status\n"

# iterate through sites
for thissite in $SITENAMES; do

    # This part of the report can happen prior to the environment loop.
    echo "Issuing terminus commands for: $thissite."
    SITEINFO="$(terminus site:info $thissite --format=csv --fields="label,name,created,framework,plan_name,upstream,last_frozen_at")"

    # Read lines from output and convert/format as needed. Line count used here to format specific parts of the returned list.
    # SITELABEL = substring from string. Pulls the first entry from the list for the domain report.
    
    linecount=1
    SITELABEL=""
    while read -r line; do
        test $linecount -eq 1 && ((linecount=linecount+1)) && continue
        PANUPSTR="e8fe8550-1ab9-4964-8838-2b9abdccf4bf: https://github.com/pantheon-systems/WordPress"
        PITCHFORK="110611cd-f04f-477b-b908-26a162c11c1f: https://github.com/asuengineering/pantheon-upstream-pitchfork.git"
        FSDT="54be9969-9f75-4096-927a-ba09f9540c02: https://github.com/asuengineering/pantheon-upstream-fsdt.git"
        ASUDIVI="17102044-7ee9-420b-bb32-d8231390e89d: https://github.com/asuengineering/pantheon-upstream-asudivi.git"
        LABSITE="ced4d8aa-4315-45ad-9e49-f335b5e9eeba: https://github.com/asuengineering/pantheon-upstream-faculty.git"
        STATIC="de858279-cb87-4664-825c-fcb4c2928717: https://github.com/populist/static-html-upstream.git"
        line=${line//$PANUPSTR/"Pantheon (Default)"}
        line=${line//$PITCHFORK/"Pitchfork"}
        line=${line//$FSDT/"FSDT"}
        line=${line//$ASUDIVI/"ASU Divi"}
        line=${line//$LABSITE/"ASU Labs"}
        line=${line//$STATIC/"Static HTML Only"}
        PANTHEONREPORT+="$line\n"
        SITELABEL=$(echo $line| cut -d',' -f 1)
        SYSTEMDOMAIN=$(echo $line| cut -d',' -f 2)
    done <<< "$SITEINFO"

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... getting domain info associated with this site's $thisenv environment."

        DNSINFO="$(terminus domain:dns $thissite.$thisenv --format=csv --fields="domain,type,value,detected_value,status")"
        
        linecount=1
        while read -r line; do
            test $linecount -eq 1 && ((linecount=linecount+1)) && continue
            DOMAINREPORT+="$SITELABEL,$line\n"
        done <<< "$DNSINFO"

        SYSTEMDOMAIN="$thisenv-$SYSTEMDOMAIN.pantheonsite.io"

        # Append system domain line to file as well. System domain = modified site "slug"
        DOMAINREPORT+="$SITELABEL,$SYSTEMDOMAIN,system,$SYSTEMDOMAIN,$SYSTEMDOMAIN,system_domain\n"

    done

    echo "... done with $thissite.\n"

done

# Append the data to a file.
# File operations here as well - check to see if the file exists, delete it, etc. 

echo "Generating plugin, theme and users lists."

# Make the files first if they don't exist.
if [ -f "$PANTHEONFILE" ]; then touch $PANTHEONFILE; fi
if [ -f "$DOMAINFILE" ]; then touch $DOMAINFILE; fi

# Write/overwrite data to the files.
echo "$PANTHEONREPORT" > "$PANTHEONFILE"
echo "$DOMAINREPORT" > "$DOMAINFILE"
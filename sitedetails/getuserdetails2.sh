#!/bin/sh
# Script to query multiple sites in Pantheon and perform a few WP-CLI commands against all of them.
#   - Gathers a list of all registered users for any site polled. Limited to LIVE sites.
#   - Adds details about that user for better communication. Details include:
#      - Theme in use, last login date, num logins over last 28 days
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
NOW30=$(date -v -30d +"%Y-%m-%d")
NOW90=$(date -v -90d +"%Y-%m-%d")
NOW180=$(date -v -180d +"%Y-%m-%d")

EMAILFILE="user-emails-$NOW.csv"
DETAILFILE="user-details-$NOW.csv"

touch $DETAILFILE

mkdir -p temp

# DETAIL="id,display_name,user_email,user_registered,roles,sitename,env,LastLogin,Total30,Total90,Total180\n"
# echo "$DETAIL" > $DETAILFILE

# Produce a list of sites for this script to query.
#  - Use site:list to produce a list for a specific team, owner, or REGEX name expression.
#  - Use org:site:list for filtering sites within an organization by a tag from the dashboard.
#  - Create a space separated list of sites if neither of these options will work for you.
# 
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="site1 site2 site3"

# SITENAMES="semte hiring furi control-systems-lab-csel advising-directory nanophotonics engineering-fulton-schools"
SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

# Indicate which environments you want the script to include.

SITEENVS="live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
echo "Getting information about ${#SITECOUNT[@]} sites."

# Preload various outputs with correct CSV title rows.
USERREPORT="site,environment,ID,login,display-name,email,register-date,roles\n"
LOGINS="logintime,id\n"
DETAIL="id,display_name,user_email,user_registered,roles,sitename,env,LastLogin,Total30,Total90,Total180\n"

# iterate through sites
for thissite in $SITENAMES; do

    # iterate through current site environments
    for thisenv in $SITEENVS; do
        echo "... issuing WP-CLI commands for: $thissite.$thisenv"

        # Terminus "pipe" command to query an individial site via WP-CLI
        # The 2>/dev/null part supresses any notices or warnings that comes from the command.
        
        # CSV output from terminus includes a title row, which we'll need to replace eventually.
        # We'll identify the first row with a counter variable and exclude it from the output.

        # Read lines from report, skip title row and append content to variable.
        # In addition to the CSV output from the WP-CLI command, we'll add the Pantheon site name and environment.

        # Users. Same as before.
        USERS="$(terminus wp $thissite.$thisenv -y -v -- user list --fields=id,display_name,user_email,user_registered,roles --format=csv 2>/dev/null)"
        LOGINS+="$(terminus wp $thissite.$thisenv -y -v -- stream query --action=login --fields=created,user_id --records_per_page=99999 --format=csv 2>/dev/null)"

        echo "$USERS" > siteusers.csv
        echo "$LOGINS" > logins.csv

        # Validate and clean the files. Delete the old stuff.
        echo "... cleaning up the .csv files from WP-CLI."
        csvclean siteusers.csv 
        csvclean logins.csv 

        rm -f siteusers_err.csv logins_err.csv
        if [ -f siteusers_out.csv ]; then 
            rm -f siteusers.csv
            mv -f siteusers_out.csv siteusers.csv
        fi

        if [ -f logins_out.csv ]; then 
            rm -f logins.csv
            mv -f logins_out.csv logins.csv
        fi

        # Create additional sitename, environment file.
        csvsql --query  "SELECT ID, '$thissite' as 'sitename', '$thisenv' as 'env' FROM siteusers;" siteusers.csv > sitename.csv

        # Create last login file
        csvsql --query  "SELECT ID, MAX(logintime) AS 'LastLogin' FROM logins GROUP BY ID;" logins.csv > logins-last.csv

        # Create frequency login count files. 30, 90, 180 days.
        csvsql --query  "SELECT ID, COUNT(*) as 'Total30' FROM logins WHERE logintime > '$NOW30' GROUP BY ID;" logins.csv > logins-30.csv
        csvsql --query  "SELECT ID, COUNT(*) as 'Total90' FROM logins WHERE logintime > '$NOW90' GROUP BY ID;" logins.csv > logins-90.csv
        csvsql --query  "SELECT ID, COUNT(*) as 'Total180' FROM logins WHERE logintime > '$NOW180' GROUP BY ID;" logins.csv > logins-180.csv

        # Join party, democrats only.
        SUMMARY="$(csvjoin -c id --left siteusers.csv sitename.csv logins-last.csv logins-30.csv logins-90.csv logins-180.csv)"

    done

    # Append rows from data.csv to user-detail.csv file. 
    linecount=1
    while read -r line; do  
        test $linecount -eq 1 && ((linecount=linecount+1)) && continue   
        DETAIL+="$line\n"
    done <<< "$SUMMARY"

    # Append to file
    echo "$DETAIL" > "$DETAILFILE"

    # Different loop to aggrigate the data into 
    #linecount=1
    #while IFS=, read -r col1 col2
    #    test $linecount -eq 1 && ((linecount=linecount+1)) && continue   
     #   DETAIL+="$line\n"
    #done <<< "$SUMMARY"

    # Cleanup
    echo "... cleaning up all non-essential csv files.\n\n"
    rm -f logins.csv logins-last.csv logins-30.csv logins-90.csv logins-180.csv
    rm -f sitename.csv siteusers.csv summary.csv

done

# After all loops completed, do some fancy SQL things to the detail file.
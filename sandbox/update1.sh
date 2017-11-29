#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Assumes a CSV exists with 5 columns of data in order listed below


# Name the target CSV for this document
# Obtained from: terminus site:list --fields="name,ID" --format=csv
INPUT=sitelist.csv
MULTIDEV=upstream-up

# Whatever the Internal File Sperator token to whatever it is before we run the script
OLDIFS=$IFS

# the Internal File Sperator token to a comma for our CSV
IFS=,

# Check if the input file exists and kill the script if not
[[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }

# while in this loop, parce the columns in the CSV as these variables
# 	sitename        = name of site (slug) in Pantheon
#   id              = not actually used, but is filler data to safeguard against nasty EOL funkiness

# Jump over the first line in the CSV. Assuming it's a title row.
clear
echo -e "Importing list of sites to be updated. Processing the title row."
i=1
while read site_name id
do
    # skip first line, otherwise increment counter
    test $i -eq 1 && ((i=i+1)) && continue

    # check for upstream updates
    echo -e "SITE: $site_name"

    # echo -e "...checking for upstream updates on the wp-update multidev..."
    UPDATES_APPLIED=false
    UPSTREAM_UPDATES="$(terminus upstream:updates:status $site_name.test  --format=list  2>&1)"

    if [[ ${UPSTREAM_UPDATES} == *"no available updates"* ]]
    then
        # no upstream updates available
        echo -e "...no upstream updates found."
    else
        # delete the multidev environment
        # echo -e "Working with the site $site_name."
        # echo -e "...deleting any existing multi-dev environments called wp-update"
        terminus multidev:delete $site_name.$MULTIDEV --delete-branch --yes

        #recreate the multidev environment
        # echo -e "...creating a multi-dev environment called wp-update as a clone of the LIVE environment."
        terminus multidev:create $site_name.live $MULTIDEV

        # making sure the multidev is in git mode
        # echo -e "\nSetting the ${MULTIDEV} multidev to git mode"
        terminus connection:set $site_name.$MULTIDEV git

        # apply WordPress upstream updates
        # echo -e "\nApplying upstream updates on the ${MULTIDEV} multidev..."
        terminus upstream:updates:apply $site_name.$MULTIDEV --yes --updatedb --accept-upstream
        UPDATES_APPLIED=true

        # echo -e "...delete the wp-update"
        terminus multidev:delete $site_name.$MULTIDEV --delete-branch --yes
    fi

# if we are not at the end of the file, we are not done, loop again
done < $INPUT

# after the loop, reset the Internal File Sperator to whatever it was before
IFS=$OLDIFS

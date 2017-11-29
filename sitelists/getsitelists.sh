#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder

# Gathers information from Pantheon and Terminus to produce a CSV file that other scripts can use.
# terminus site:list --format=csv --fields="Name,ID,Created,service_level,framework,owner"

# TODO: Use org:site:list and filter the produced CSV into smaller chunks via tags present.

echo -e "Creating: terminus site:list as a CSV.\nFields used are Name, ID, Created, Service Level, Framework, Owner"

DATA="$(terminus site:list --format=csv --fields="Name,ID,Created,service_level,framework,owner")"
FILE=pantheon_all.csv

echo "$DATA" > $FILE
echo -e "Done. Happy Scripting!\n"
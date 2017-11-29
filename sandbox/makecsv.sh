#!/bin/bash
# Author: Steve Ryan, steve.ryan@asu.edu
# Borrows from: https://github.com/mcdwayne/pantheon_sites_from_csv_script_builder
# Assumes a CSV exists with 5 columns of data in order listed below

# Lets get Bash to make a CSV file for us, first.
csv_file=$(terminus site:list --fields="name" --format=csv)
echo csv_file
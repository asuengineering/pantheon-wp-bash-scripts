#!/bin/bash
# Author: 1dwayne.mcdaniel@gmail.com
# version 1.0
# For educational purposes only to demonstrate how to build multiple sites on Pantheon with a script
# Assumes a CSV exists with 5 columns of data in order listed below

#Name the target CSV for this document
INPUT=data1.csv

# Whatever the Internal File Sperator token to whatever it is before we run the script
OLDIFS=$IFS
# the Internal File Sperator token to a comma for our CSV
IFS=,

# Check if the input file exists and kill the script if not
[[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }

# while in this loop, parce the columns in the CSV as these variables
#	firstname is the new site owner's first name
# 	sitename is the name of the site on Pantheon 
# 	wp_email is the email you want to use for wp-admin
# 	pantheon_email is the email for the end users' Pantheon account
# 	lastname is not actually used but is fille data to safeguard against nasty EOL funkiness
while read  firstname site_name wp_email pantheon_email lastname
do
	# Note: only reason I am echoing this is to build another script to do this at scale.  
	# If run as just Terminus commands in loop, it stops after first row for some reason.

	# Create the site on Pantheon inside the Org of person running script
	echo "terminus site:create --org=<org-UUID> -- ${site_name} ${site_name} WordPress"

	# Install site on 
	echo "terminus wp ${site_name}.dev -- core install --url=dev-${site_name}.pantheonsite.io --title=WordCampLA --admin_user=${firstname} --admin_wp_email=${wp_email}"
	
	# Install and activate the theme of choice.  Replace <theme> with theme of choice on repo or zip location
	echo "terminus wp ${site_name}.dev -- theme install <theme> --activate"
	
	# Delete the themes we will not be using
	echo "terminus wp ${site_name}.dev -- theme delete twentyseventeen twentysixteen twentyten twentyeleven twentytwelve twentythirteen twentyfourteen twentyfifteen"

	# Just make sure the theme is up to date, just in case 
	echo "terminus wp ${site_name}.dev -- theme update --all"
	
	# Install and activate the plugins of choice.  Replace variables with plugins of choice
	echo "terminus wp ${site_name}.dev -- plugin install <plugin1> <plugin2> <plugin3> <plugin4> --activate"

	# Just make sure they are up to date
	echo "terminus wp ${site_name}.dev -- plugin update --all"

	# I want the post URLs to be example.com/postname on this site
	echo "terminus wp ${site_name}.dev -- rewrite structure '%postname%'"

	# The site should be in SFTP mode from this creation process, so let's commit all these changes now
	echo "terminus env:commit ${site_name} --force"

	# Add the user to the Pantheon team
	echo "terminus site:team:add ${site_name} ${pantheon_email}"

	# Since this is a Sandbox on Pantheon, we can set ownership
	echo "terminus owner:set ${site_name} ${pantheon_email}"

	# Remove ths site from the script runner's org, since this is for creating stand alone site for students
	echo "terminus org:site:remove <org-UUID> ${site_name}"

	# Remove the site creator from the site to complet the handoff of the site. 
	echo "terminus site:team:remove ${site_name} <email of the person running script>"

# if we are not at the end of the file, we are not done, loop again
done < $INPUT

# after the loop, reset the Internal File Sperator to whatever it was before
IFS=$OLDIFS

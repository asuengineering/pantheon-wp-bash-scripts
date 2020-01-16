 #!/bin/sh
# Script to query multiple sites in Pantheon and perform a few WP-CLI commands against all of them.
#   - Gathers a plugin list for all sites/environments and creates one big CSV file for them.
#   - Gathers the active theme for all sites and compiles that list as well. Exports CSV.
#   - Gather a list of all registered users for any site polled. Limited to LIVE sites. Exports CSV.
#
# Requirements:
#   - Access to Pantheon's terminus CLI
# 

# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="site1 site2 site3"

#SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
SITENAMES="nanofab progressive-learning-platform stabenfeldt-lab gcsp fse-upstreamtesting sw-robotics-symposium sensip invest-campaign2020 plaisierlab water-environmental-technology-wet lab-interactive-robots rossum fac-aditi lab-anamitra-pal fac-azeredo lab-aaml 3d-print-lab asce mascaro includes allee-group iise lab-nielsen angelia sarma-iot graduate-programs fac-yong lab-slate-lab rehabrobotics nasa-uli fac-ruben-acuna blockchain-research online-student leadership-program young-engineers air-devils society-women-engineers peralta-engineering-studio holman-research-group research-themes-retired-2018 ewb events-guide ieee kyle-squires hkn convocation fulton-schools-divi-theme-test entrepreneurship construction-del-webb brain-center-neurotechnology lab-make wics lab-hell academic-student-affairs-intranet lab-eer ecee-fsdt fulton-outreach lab-datasystemslab fac-yezhou-yang wisca metis-center ls2016 rege-bioengineering-lab lab-bliss mav poly-home sdsl lab-aims maes tomnet-utc faculty-assembly fse-homecoming sase lak19 fse-site-setup 4dms-center muhich-lab sustainable-engineering fac-yan-chen lab-defect awic sbhse-fsdt sun-devil-robotics nannenga engineering-technical-services lab-hildreth tutoring-center fac-javier-gonzalez-sanchez academicbowl acims sops lw2017 fulton-student-council sierks-lab"
SITEENVS="dev test live"

# Counting the number of iterations in the whole script.
SITECOUNT=($SITENAMES)
SITEENVCOUNT=($SITEENVS)

# iterate through sites
SITECOUNT=($SITENAMES)
echo "Applying upstream code changes for ${#SITECOUNT[@]} sites.\n"
SITENUM=0
for thissite in $SITENAMES; do

    # Flag to decide whether an update was applied to a site. Useful later.
    UPDATEFLAG=false
    SITENUM=$[SITENUM + 1]
    # check for upstream updates
    echo "Working with site $SITENUM of ${#SITECOUNT[@]}: $thissite"
    FRAMEWORK="$(terminus site:info $thissite --field="framework")"
    if [[ $FRAMEWORK != "wordpress" ]]; then
        echo "... this isn't WordPress. Let's skip it."
        continue
    fi

    for thisenv in $SITEENVS; do

        if [[ "$thisenv" == "dev" ]]; then

            # Check the site for updates present, and attempt to apply them normally.
            UPDATEAVAIL="$(terminus upstream:updates:status $thissite.$thisenv)"
            if [[ "$UPDATEAVAIL" == "outdated" ]]; then

                echo "... updates are available."

                # Create backup for live version of the site.
                echo "... creating a backup of the code base & database for the live environment."
                terminus backup:create $thissite.live --element="code" -q
                terminus backup:create $thissite.live --element="db" -q

                echo "... switching to git mode, attempting to apply updates."
                terminus connection:set $thissite.$thisenv git -q
                terminus upstream:updates:apply $thissite.$thisenv --yes --accept-upstream -q
                
                # test again to see if it worked.
                UPDATEAPPLIED="$(terminus upstream:updates:status $thissite.$thisenv)"
                if [[ "$UPDATEAPPLIED" == "current" ]]; then
                    echo "... updates applied to site normally."
                    UPDATEFLAG=true
                elif [[ "$UPDATEAPPLIED" == "outdated" ]]; then
                    # Merge conficts exist. Recommend manual GIT merge conflict resolution.
                    echo "... *** HEADS UP ***"
                    echo "... a merge confict exists with the site's codebase. Automatically accepting the upstream didn't work."
                    echo "... resolve the conflict manually or run a different script to automatically update in favor of the upstream."
                    echo "... ****************"
                fi

            elif [[ "$UPDATEAVAIL" == "current" ]]; then
                echo "... no upstream updates found."
                continue
            fi
        
        elif [[ "$thisenv" == "test" ]] ; then

            echo -e "... attempting to deploy code to the $thisenv environment."
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

        elif [[ "$thisenv" == "live" ]] ; then

            echo -e "... attempting to deploy code to the $thisenv environment."
            terminus env:deploy $thissite.$thisenv --sync-content --cc --note="Updates deployed via automated bash script."

            echo "... configuring plugins that were recently installed."
            terminus wp $thissite.$thisenv -- plugin activate tinymce-advanced enable-media-replace
            terminus wp $thissite.$thisenv -- option patch delete "tadv_admin_settings" "options"

        fi
    
    done
    
    echo "...no automated testing was done on SITE: $thissite."
    echo "...instead, opening in a browser for human eyeball testing."
    terminus env:view $thissite.live 
    echo "Work complete with $thissite.\n"

done

echo -e "Script complete."
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

# SITENAMES="career-center cidse-fulton fullcircle intheloop sdsl sensip"
# SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --upstream="17102044-7ee9-420b-bb32-d8231390e89d" --field="name")"
SITENAMES="iac-engineering futures2020 advising-directory edo-resources energy-power-solutions-leaps comm-engineering dpse asu-divi-setup-site research-themes lab-grau sensip-lab nestt zimin-institute vijay-vittal nasa-leadership cen mechanics-infrastructure-materials graduate-programs-2019 ireccee lab-ivu cidse2 safe-engineering tomnet-utc events-planning-guide-2019 julianne-holloway sdsl-lab safety-engineering larry-mays-ssebe sensip fepp lab-interactive-robots richard-king fse-employees mmmplab urbanagnexus christ-richmond-ecee computing-programs tutoring2020 front-end-planning asu-mayo-imaging advising2 semte-postersymposium devils-invent peralta-engineering-studio cement-mobasher kumar-ankit kyle-squires fse-tour 3d-printlab git-photography sbhse-new energyefficiency invest2020 sdsl prevention-through-design dimitri-bertsekas robotics-ms gcsp2 dean-squires ces2 magic-lab peer-collaborative"

# iterate through sites
for thissite in $SITENAMES; do

    NINJA="$(terminus wp $thissite.live -- user get fultonweb@asu.edu --field=ID)"
    terminus wp $thissite.live -- user delete irene@thewordpress-expert.com --reassign=$NINJA

done


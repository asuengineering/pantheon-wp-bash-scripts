#!/bin/sh
# Script to query multiple sites in Pantheon and perform a few arbitrary terminus commands against all of them.
#
# Requirements:
#   - Access to Pantheon's terminus CLI
# 
# Inspiration:
#   - Looping logic came from here: https://pantheon.io/docs/backups/#access-backups
# 

SITENAMES="lab-elab engineering-fulton-schools nanophotonics additive-manufacturing sbhse advising-directory lab-home semte-business-services edo-resources energy-power-solutions-leaps faculty-sankar roadmap nasa-space-grant-robotics conroy-ben-lab kannan-lab hoover-lab lab-grau fullcircle xiangfan-chen ecocar3 nik-chawla neithalath-lab sensip-2014 acharya engineering-futures lab-pavements cen ssebe-today lab-scaglione fac-qiongnian lab-underwood grace-hopper global-center-for-safety-initiative e2camp uspcase engineering-labs-overview studentorgs lab-adapt fse-study-abroad fac-kodibagkarlab research-themes aiaa naesc asu-mbe cnce cidse-2017 transfer lab-avnetinnovationlab fso-cbbg global-resolve undergraduate-research intheloop air-capture-technology-consortium-act lab-mfix-dem-phi pavements-summit lab-ivu lab-ipa lab-2sigma-new em-symposium cooperative-robotics furi safe-engineering zhuang mctb-symposium ssebe-fsdt sun-devil-racing-development faculty-wang-chao next-steps old-full-circle-review amcii asu-industrial-assessment-center sbhse-dev nanofab progressive-learning-platform stabenfeldt-lab gcsp lab-cysis ux-innovation-lab fse-upstreamtesting sw-robotics-symposium sensip asu-photography invest-campaign2020 plaisierlab semte lab-birth water-environmental-technology-wet lab-interactive-robots rossum lab-newt fac-aditi ecee lab-anamitra-pal fac-azeredo lab-aaml career-center lab-dream 3d-print-lab asce mascaro includes allee-group iise lab-nielsen angelia sarma-iot graduate-programs fac-yong lab-slate-lab rehabrobotics nasa-uli fse-volunteer fac-ruben-acuna blockchain-research hiring online-student leadership-program young-engineers air-devils society-women-engineers peralta-engineering-studio cement-mobasher holman-research-group innercircle richard-king-lab epics ewb poly-computer-science-club events-guide events-inventory ieee explore kyle-squires bmes hkn nestt fse-tour voctec convocation wind-lab asu-smart-nce entrepreneurship lab-icet startup-center semte-dev construction-del-webb brain-center-neurotechnology lab-make wics lab-hell hsee academic-student-affairs-intranet candace-chan lab-eer ecee-fsdt fulton-outreach lab-datasystemslab fac-yezhou-yang wisca metis-center nerd-herd ls2016 rege-bioengineering-lab lab-bliss mav poly-home sdsl lab-aims lab-xlab maes tomnet-utc robotics-ms faculty-assembly sun-devil-engineering fse-homecoming faculty-ankit sase lak19 fse-site-setup dewsc e2c2 4dms-center lc-nano muhich-lab sustainable-engineering fac-yan-chen lab-defect advanced-tech-innovation-atic awic sbhse-fsdt lab-mobilebench labspace-signup sun-devil-robotics nannenga engineering-technical-services cidse-fulton lab-hildreth fse-communications tutoring-center fac-javier-gonzalez-sanchez academicbowl acims first-year faculty-kitchen fse-partners sops lw2017 fulton-student-council sierks-lab fse-scholarships customize"
# SITENAMES="additive-manufacturing energy-power-solutions-leaps roadmap"
# iterate through sites
for thissite in $SITENAMES; do
    echo "For $thissite: Switching upstreams to FSDT WordPress. Deploying any changes to DEV."
    terminus site:upstream:set $thissite fsdt-wordpress -y
    terminus upstream:updates:apply $thissite.dev --accept-upstream
    echo "... done with $thissite.\n"
done


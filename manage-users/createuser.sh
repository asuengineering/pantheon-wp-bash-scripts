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

# SITENAMES="aiaa angelia asce asu-industrial-assessment-center career-center cidse-2017 cidse-fulton cooperative-robotics dewsc divi-help-site em-symposium engineering-futures ewb fac-azeredo fac-javier-gonzalez-sanchez fac-kodibagkarlab fac-qiongnian fac-ruben-acuna fac-yong faculty-sankar faculty-wang-chao fullcircle gcsp global-center-for-safety-initiative graduate-programs ieee iise innercircle intheloop lab-adapt lab-avnetinnovationlab lab-birth lab-bliss lab-cysis lab-datasystemslab lab-defect lab-dream lab-eer lab-elab lab-grau lab-hell lab-hildreth lab-icet lab-interactive-robots lab-ipa lab-make lab-mobilebench lab-pavements lab-scaglione lab-underwood lab-xlab labspace-signup lw2017 mascaro mav mctb-symposium pavements-summit rehabrobotics research-themes robotics-research sbhse sdsl semte sensip sops studentorgs sustainable-engineering tomnet-utc tutoring-center web-help young-engineers "
# SITENAMES="career-center cidse-fulton fullcircle intheloop sdsl sensip"
# SITENAMES="$(terminus org:site:list asu-engineering --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --upstream="17102044-7ee9-420b-bb32-d8231390e89d" --field="name")"
SITENAMES="asu-industrial-assessment-center fse-communications"

# iterate through sites
for thissite in $SITENAMES; do
    terminus wp $thissite.live -- user create imilhorn irene@thewordpress-expert.com --role=administrator --user_pass="Stratocaster-6-String"
done


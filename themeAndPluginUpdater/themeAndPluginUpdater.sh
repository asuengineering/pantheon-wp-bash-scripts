# St of sites used as reference to ommit the set of plugins and themes which are part of upstreams
REFERENCESITES="$(terminus org:site:list asu-engineering --tag="plugin-list" --field="name")"

# Enable SFTP mode for all reference sites
for refsite in $REFERENCESITES; do
    terminus connection:set $refsite.dev sftp -q
done

ENVLOOP=('dev' 'test' 'live')

# Produce a list of sites for this script to query.
#  - Use site:list to produce a list for a specific team, owner, or REGEX name expression.
#  - Use org:site:list for filtering sites within an organization by a tag from the dashboard.
#  - Create a space separated list of sites if neither of these options will work for you.
# 
# SITENAMES="$(terminus site:list --field="name")"
# SITENAMES="$(terminus org:site:list asu-engineering --tag="schools" --field="name")"
# SITENAMES="site1 site2 site3"
SITENAMES="$(terminus org:site:list asu-engineering --field="name")"

for thissite in $SITENAMES; do
    FRAMEWORK="$(terminus site:info $thissite --field=framework)"
    # Works only for the sites which have Wordpress as the framework
    if [ $FRAMEWORK == "wordpress" ];
    then
    
        for thisenv in "${ENVLOOP[@]}"; do
            if [[ "$thisenv" == "dev" ]]; then
            
                # Setting the connection to SFTP
                terminus connection:set $thissite.$thisenv sftp -q
                echo "... issuing WP-CLI commands for: $thissite.$thisenv"
                
                #Retreiving the Upstream Id for the site being queried
                UPSTREAMID="$(terminus site:info --field Upstream $thissite)"
                for thispluginsite in $REFERENCESITES; do
                    
                    # Comparing the upstream Id with the reference site and updating the theme and the plugin accordingly
                    if [[ ! -z $(terminus site:info --field Upstream $thispluginsite | grep -o "$UPSTREAMID") ]]; then
                        NOPLUGINUPDATE="$(terminus wp $thispluginsite.$thisenv -- plugin list --format="csv" --field="name")"
                        NOTHEMEUPDATE="$(terminus wp $thispluginsite.$thisenv -- theme list --format="csv" --field="name")"
                        terminus wp $thissite.$thisenv -y -v -- plugin update --all --exclude="$NOPLUGINUPDATE"
                        terminus wp $thissite.$thisenv -y -v -- theme update --all --exclude="$NOTHEMEUPDATE"
                    fi
                done

                    # Checks for SFTP Mode, quietly.
                    terminus connection:set $thissite.$thisenv sftp -q
                    # Committing the changes to the dev
                    terminus env:commit $thissite.$thisenv --yes --message="Updates deployed via automated bash script."

            elif [[ "$thisenv" == "test" ]] || [[ "$thisenv" == "live" ]]; then
                
                # Deploying code to test and live environment
                echo -e "...deploying code to the $thisenv environment."
                terminus env:deploy $thissite.$thisenv --sync-content --updatedb --cc --note="Updates deployed via automated bash script."
            fi
        done
        
        # Setting the connection back to git.
        terminus connection:set $thissite.dev git -q
    fi
done 

for refsite in $REFERENCESITES; do
    terminus connection:set $refsite.dev git -q
done

echo "End."
# pantheon-wp-bash-scripts
A collection of Terminus / WP-CLI scripts that we find useful for housekeeping purposes.
- `sitedetails/getsitedetails.sh` produces plugin, theme and user data for a group of sites. WordPress specific, as written.
- `pantheon-details/getpantheondetails.sh` produces Pantheon container, domain name and DNS data for a group of sites.

# Version
- 0.2: Added Pantheon Details report.
- 0.1: Added site details report, featuring WP-CLI commands.

# RSA Key Fingerprint Warnings
These script can produce a whole lot of RSA key fingerprint warnings, since they potentiall connect to all sites in your Pantheon org.
Those warnings look like:
```
The authenticity of host '[appserver.live.######.drush.in]' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

This problem can be overcome by creating an entry in your local `$HOME/.ssh/config` file:
```
Host *.drush.in
  HostKeyAlias pantheon-systems.drush.in
  ```
... which should alias all IP addresses coming from Pantheon to one entry in the `known_hosts` file. Just say yes to the prompt once more and you're done.

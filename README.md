# pantheon-wp-bash-scripts
A collection of Terminus / WP-CLI scripts that we find useful around here.

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

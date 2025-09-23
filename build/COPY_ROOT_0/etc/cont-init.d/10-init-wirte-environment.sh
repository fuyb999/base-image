#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.

 # Ensure all variables available for interactive sessions
sed -i '7,$d' /opt/ai-dock/etc/environment.sh
while IFS='=' read -r -d '' key val; do
    if [[ $key != "HOME" ]]; then
        env-store "$key"
    fi
done < <(env -0)

if [[ ! $(grep "# First init complete" /root/.bashrc) ]]; then
    printf "# First init complete\n" >> /root/.bashrc
    printf "umask 002\n" >> /root/.bashrc
    printf "source /opt/ai-dock/etc/environment.sh\n" >> /root/.bashrc
    printf "nvm use default > /dev/null 2>&1\n" >> /root/.bashrc
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
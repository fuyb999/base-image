#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

 # Ensure all variables available for interactive sessions
sed -i '7,$d' /opt/ai-dock/etc/environment.sh
while IFS='=' read -r -d '' key val; do
    if [[  $key != "HOME" ]]; then
        env-store "$key"
    fi
done < <(env -0)

if [[ ! $(grep "# First init complete" /root/.bashrc) ]]; then
    printf "# First init complete\n" >> /root/.bashrc
    printf "umask 002\n" >> /root/.bashrc
    printf "source /opt/ai-dock/etc/environment.sh\n" >> /root/.bashrc
    printf "nvm use default > /dev/null 2>&1\n" >> /root/.bashrc

    if [[ -n $PYTHON_DEFAULT_VENV ]]; then
        printf '\nif [[ -d $WORKSPACE/environments/python/$PYTHON_DEFAULT_VENV ]]; then\n' >> /root/.bashrc
        printf '    source "$WORKSPACE/environments/python/$PYTHON_DEFAULT_VENV/bin/activate"\n' >> /root/.bashrc
        printf 'else\n' >> /root/.bashrc
        printf '    source "$VENV_DIR/$PYTHON_DEFAULT_VENV/bin/activate"\n' >> /root/.bashrc
        printf 'fi\n' >> /root/.bashrc
    fi

    printf "cd %s\n" "$WORKSPACE" >> /root/.bashrc
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
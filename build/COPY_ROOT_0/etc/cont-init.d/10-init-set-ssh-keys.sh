#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

if [[ -f "/root/.ssh/authorized_keys_mount" ]]; then
  cat /root/.ssh/authorized_keys_mount > /root/.ssh/authorized_keys
fi

# Named to avoid conflict with the cloud providers below

if [[ -n $SSH_PUBKEY ]]; then
    printf "\n%s\n" "$SSH_PUBKEY" > /root/.ssh/authorized_keys
fi

# Alt names for $SSH_PUBKEY
# runpod.io
if [[ -n $PUBLIC_KEY ]]; then
    printf "\n%s\n" "$PUBLIC_KEY" > /root/.ssh/authorized_keys
fi

# vast.ai
if [[ -n $SSH_PUBLIC_KEY ]]; then
    printf "\n%s\n" "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
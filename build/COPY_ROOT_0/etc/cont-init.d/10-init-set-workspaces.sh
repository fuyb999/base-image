#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# no defined workspace - Keep users close to the install
if [[ -z $WORKSPACE ]]; then
    export WORKSPACE="/opt/"
else
    ws_tmp="/$WORKSPACE/"
    export WORKSPACE=${ws_tmp//\/\//\/}
fi

WORKSPACE_UID=$(stat -c '%u' "$WORKSPACE")
if [[ $WORKSPACE_UID -eq 0 ]]; then
    WORKSPACE_UID=1000
fi
export WORKSPACE_UID

WORKSPACE_GID=$(stat -c '%g' "$WORKSPACE")
if [[ $WORKSPACE_GID -eq 0 ]]; then
    WORKSPACE_GID=1000
fi
export WORKSPACE_GID

if [[ -f "${WORKSPACE}".update_lock ]]; then
    export AUTO_UPDATE=false
fi

if [[ $WORKSPACE != "/opt/" ]]; then
    mkdir -p "${WORKSPACE}"
    chown ${WORKSPACE_UID}.${WORKSPACE_GID} "${WORKSPACE}"
    chmod g+s "${WORKSPACE}"
fi

# Determine workspace mount status
if mountpoint "$WORKSPACE" > /dev/null 2>&1 || [[ $WORKSPACE_MOUNTED == "force" ]]; then
    export WORKSPACE_MOUNTED=true
    mkdir -p "${WORKSPACE}"storage
    mkdir -p "${WORKSPACE}"environments/{python,javascript}
else
    export WORKSPACE_MOUNTED=false
    ln -sT /opt/storage "${WORKSPACE}"storage > /dev/null 2>&1
    no_mount_warning_file="${WORKSPACE}WARNING-NO-MOUNT.txt"
    no_mount_warning="$WORKSPACE is not a mounted volume.\n\nData saved here will not survive if the container is destroyed.\n\n"
    printf "%b" "${no_mount_warning}"
    touch "${no_mount_warning_file}"
    printf "%b" "${no_mount_warning}" > "${no_mount_warning_file}"
    if [[ $WORKSPACE != "/opt/" ]]; then
        printf "Find your software in /opt\n\n" >> "${no_mount_warning_file}"
    fi
fi
# Ensure we have a proper linux filesystem so we don't run into errors on sync
if [[ $WORKSPACE_MOUNTED == "true" ]]; then
    test_file=${WORKSPACE}/.ai-dock-permissions-test
    touch $test_file
    if chown ${WORKSPACE_UID}.${WORKSPACE_GID} $test_file > /dev/null 2>&1; then
        export WORKSPACE_PERMISSIONS=true
    else
        export WORKSPACE_PERMISSIONS=false
    fi
    rm $test_file
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
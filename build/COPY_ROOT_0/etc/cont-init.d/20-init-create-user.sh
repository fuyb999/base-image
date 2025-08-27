#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# This is a convenience for X11 containers and bind mounts - No additional security implied.
# These are interactive containers; root will always be available. Secure your daemon.

if [[ ${WORKSPACE_MOUNTED,,} == "true" ]]; then
    home_dir=${WORKSPACE}home/${USER_NAME}
    mkdir -p $home_dir
    ln -s $home_dir /home/${USER_NAME}
else
    home_dir=/home/${USER_NAME}
    mkdir -p ${home_dir}
fi
chown ${WORKSPACE_UID}.${WORKSPACE_GID} "$home_dir"
chmod g+s "$home_dir"
groupadd -g $WORKSPACE_GID $USER_NAME
useradd -ms /bin/bash $USER_NAME -d $home_dir -u $WORKSPACE_UID -g $WORKSPACE_GID
printf "user:%s" "${USER_PASSWORD}" | chpasswd
usermod -a -G $USER_GROUPS $USER_NAME

# For AMD devices - Ensure render group is created if /dev/kfd is present
if ! getent group render >/dev/null 2>&1 && [ -e "/dev/kfd" ]; then
    groupadd -g "$(stat -c '%g' /dev/kfd)" render
    usermod -a -G render $USER_NAME
fi

# May not exist - todo check device ownership
usermod -a -G sgx $USER_NAME
# See the README (in)security notice
printf "%s ALL=(ALL) NOPASSWD: ALL\n" ${USER_NAME} >> /etc/sudoers
sed -i 's/^Defaults[ \t]*secure_path/#Defaults secure_path/' /etc/sudoers
if [[ ! -e ${home_dir}/.bashrc ]]; then
    cp -f /root/.bashrc ${home_dir}
    cp -f /root/.profile ${home_dir}
    chown ${WORKSPACE_UID}:${WORKSPACE_GID} "${home_dir}/.bashrc" "${home_dir}/.profile"
fi
# Set initial keys to match root
if [[ -e /root/.ssh/authorized_keys && ! -d ${home_dir}/.ssh ]]; then
    rm -f ${home_dir}/.ssh
    mkdir -pm 700 ${home_dir}/.ssh > /dev/null 2>&1
    cp -f /root/.ssh/authorized_keys ${home_dir}/.ssh/authorized_keys
    chown -R ${WORKSPACE_UID}:${WORKSPACE_GID} "${home_dir}/.ssh" > /dev/null 2>&1
    chmod 600 ${home_dir}/.ssh/authorized_keys > /dev/null 2>&1
    if [[ $WORKSPACE_MOUNTED == 'true' && $WORKSPACE_PERMISSIONS == 'false' ]]; then
        mkdir -pm 700 "/home/${USER_NAME}-linux"
        printf "StrictModes no\n" > /etc/ssh/sshd_config.d/no-strict.conf
    fi
fi

# Set username in startup sctipts
#sed -i "s/\$USER_NAME/$USER_NAME/g" /etc/supervisor/supervisord/conf.d/*

# vim:ft=sh:ts=4:sw=4:et:sts=4
#!/usr/bin/env bash

############### Setup tools
msg() {
    d="\e[33m"  # opening ansi color code for yellow text
    e="\e[0m"   # ending ansi code
    printf '%b%b%b\n' "$d" "$1" "$e" >&2
}

############### Basic Setup
msg "=== Starting bootstrap process!\n"

msg "Check for support on this machine."

if [ ! -f /etc/os-release ]; then
    msg "No /etc/os-release file found. You're likely on an unsupported distribution."
    exit -1
fi

source /etc/os-release

# If we're not on Fedora or CentOS then we can bail out
if [ "$ID" != "fedora" ] && [ "$ID" != "centos" ]; then
    msg "Sorry, not on a supported distribution."
    exit -1
fi

# setup our package manager
if [ "$ID" = "fedora" ] && [ "$VERSION_ID" -gt 22 ]; then
    pm="dnf"

else
    pm="yum"
fi

msg "Checking for system updates and installing dependencies."
# install packages
if [ "$ID" = "centos" ]; then
    $pm install epel-release -y
    $pm install python python-pip -y
fi

if [ "$ID" = "fedora" ] && [ "$VERSION_ID" -gt 22 ]; then
    $pm install python2-dnf -y
fi

# install pre-requisites
$pm makecache
$pm install git ntp ansible libselinux-python -y

# run updates after installation of packages to avoid conflicts
updates_applied=0


if ! $pm check-update; then
    msg "Updates are required. Applying. Please be patient."
    $pm update -y
    updates_applied=1
fi

msg "Enabling required services."

# when rebooting don't boot into graphical mode
systemctl set-default multi-user.target

# enable SSH service
msg "-- install and enable SSH server"
systemctl enable sshd.service
systemctl start sshd.service

# update time and enable ntp
msg "-- update time via NTP and start daemon; enable and start service"
ntpdate pool.ntp.org
systemctl enable ntpd.service
systemctl start ntpd.service

# install docker
msg "-- install and enable Docker server, client, and compose"
$pm install docker docker-client -y
if [ "$ID" = fedora ]; then
    $pm install docker-compose -y
else
    pip install docker-compose
fi

groupadd docker     # add docker group so we can add toad user to it
if [ "$ID" = "fedora" ]; then
    systemctl enable docker-containerd.service
    systemctl start docker-containerd.service
fi
systemctl enable docker.service
systemctl start docker.service

# create toad user
msg "Creating and setting up system user TOAD will run as."

if ! id toad > /dev/null 2>&1; then
    adduser toad

    # permissions for sudo
    cat > /etc/sudoers.d/toad <<EOF
toad        ALL=(ALL)       NOPASSWD:ALL
EOF

    usermod -aG docker toad     # add toad to the docker group
fi

# clone TOAD as the toad user
msg "Getting TOAD from upstream."
su - toad
cd "$HOME" || exit
if [ ! -d toad ]; then
    git clone https://github.com/redhat-nfvpe/toad.git
    cd toad || exit
    ansible-galaxy install -r requirements.yml
fi

# return from whence we came
logout

if [ $updates_applied -ne 0 ]; then
    msg "[!!] Updates were applied to your system. Rebooting is recommended.\n"
fi

msg "=== TOAD bootstrap is completed!"
msg "    Additional setup still required. Please see: https://github.com/redhat-nfvpe/toad#base-deployment-docker"

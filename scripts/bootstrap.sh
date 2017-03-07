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
if [ "$ID" = "fedora" ] && [ $VERSION_ID > 22 ]; then
    pm="dnf"

else
    pm="yum"
fi

msg "Checking for system updates and installing dependencies."
# install packages
if [ "$ID" = "centos" ]; then
    $pm install epel-release -y
fi

# install pre-requisites
$pm install --best --allow-erasing vim-enhanced git ntp ansible -y

# run updates after installation of packages to avoid conflicts
$pm check-update

updates_applied=0
if [ $? -ne 0 ]; then
    $pm update -y
    updates_applied=1
fi

msg "Enabling required services."

# when rebooting don't boot into graphical mode
systemctl set-default multi-user.target

# enable SSH service
systemctl enable sshd.service
systemctl start sshd.service

# update time and enable ntp
ntpdate pool.ntp.org
systemctl enable ntpd.service
systemctl start ntpd.service

# install docker
$pm install docker docker-client docker-compose -y
systemctl enable docker-containerd.service
systemctl enable docker.service
systemctl start docker-containerd.service
systemctl start docker.service

msg "Creating and setting up system user TOAD will run as."

# create toad user
getent passwd toad > /dev/null 2&>1
if [ $? -eq 0 ]; then
    adduser toad

    # permissions for sudo
    cat > /etc/sudoers.d/toad <<EOF
toad        ALL=(ALL)       NOPASSWD:ALL
EOF
fi

cat /home/toad/.bashrc | grep -xqFe 'alias docker="sudo /usr/bin/docker"'
if [ $? -ne 0 ]; then
    cat >> /home/toad/.bashrc <<EOF
alias docker="sudo /usr/bin/docker"
alias docker-compose="sudo /usr/bin/docker-compose"
EOF
fi

# clone TOAD as the toad user
su - toad
cd $HOME
if [ ! -d toad ]; then
    git clone https://github.com/redhat-nfvpe/toad.git
    cd toad
    ansible-galaxy install -r requirements.yml
fi

# return from whence we came
logout

if [ $updates_applied -ne 0 ]; then
    msg "[!!] Updates were applied to your system. Rebooting is recommended.\n"
fi

msg "=== TOAD bootstrap is completed!"
msg "    Now run 'cd toad ; docker-compose up -d' as the toad user."

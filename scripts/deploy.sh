#!/usr/bin/env bash

############### Setup tools
msg() {
    d="\e[33m"  # opening ansi color code for yellow text
    e="\e[0m"   # ending ansi code
    printf '%b%b%b\n' "$d" "$1" "$e" >&2
}

############### Basic deployment

msg "[!!!] This script will change the 'toad' user password and wipe its ssh keys. Ctrl-C now to quit."
sleep 6

current_user=$(whoami)

if [ "$current_user" != "toad" ]; then
    msg "Please run this as the 'toad' user after bootstrapping."
    exit -1
fi

msg "Setup the 'toad' user password for all-in-one."
sudo /bin/bash -c 'echo "toad" | passwd toad --stdin'

pushd "$HOME/toad"

msg "Generating SSH key for toad and setting public key in authorized_keys"
(mkdir ~/.ssh && chmod 700 ~/.ssh/) || true
rm -f ~/.ssh/id_toad*
rm -f ~/.ssh/authorized_keys
ssh-keygen -t rsa -f ~/.ssh/id_toad -N ''
cat ~/.ssh/id_toad.pub >> ~/.ssh/authorized_keys
chmod 0644 ~/.ssh/authorized_keys

msg "Configuring ~/.ansible/vars/toad_vars.yml."
mkdir -p ~/.ansible/vars/
cat > ~/.ansible/vars/toad_vars.yml <<EOF
elk_deployed: false
filebeat_deployed: false
EOF

msg "Setting up our slave configuration."
cat > hosts/minions <<EOF
[jenkins_slave]
slave01 ansible_connection=ssh ansible_host=172.18.0.1 ansible_user=toad ansible_ssh_private_key_file=/home/toad/.ssh/id_toad

[jenkins_slave:vars]
slave_description=TOAD Testing Node
slave_remoteFS=/home/stack
slave_port=22
slave_credentialsId=stack-credential
slave_label=toad
EOF

msg "Spinning up a Jenkins Master."
docker-compose up -d jenkins_master

msg "Deploying a Jenkins Master and Slave."
ansible-playbook site.yml --limit jenkins_master -e use_openstack_deploy=false -e deploy_type='docker' -c docker

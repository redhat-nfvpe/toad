# ansible-cira

[![Build Status](https://travis-ci.org/redhat-nfvpe/ansible-cira.svg?branch=master)](https://travis-ci.org/redhat-nfvpe/ansible-cira)

Deploy a continuous integration reference architecture with Jenkins to test
OpenStack with [TripleO
Quickstart](https://github.com/openstack/tripleo-quickstart).

# Requirements

There are two ways to install CIRA. You deploy locally into a development
environment using Vagrant, or you can deploy to an OpenStack instance. Below
you will find the list of requirements for each of the deployment scenarios.

For Ansible, several roles are required, and you can install them as follows:

    ansible-galaxy install -r requirements.yml

## Vagrant

Deployment to Vagrant should be straight forward. The only real dependency is
Vagrant itself, along with whatever provider backend you wish to utilize. Our
preferred provider is libvirt (KVM). In order to use Vagrant with the libvirt
provider, you'll need to install a new provider plugin.

    vagrant plugin install vagrant-libvirt

Additional information about other dependencies required by vagrant-libvirt are
available at https://github.com/vagrant-libvirt/vagrant-libvirt

## OpenStack

You'll need to install the `shade` dependency so that you can interact with
OpenStack (assuming you are deploying to an OpenStack cloud).

    pip install --user shade

### Setup OpenStack Connection

If you're going to install to an OpenStack cloud, you'll need to configure a
cloud to connect to. You can do this by creating the `~/.config/openstack/`
directory and placing the following contents into the `clouds.yml` file within
that directory (adjust to your own cloud connection):

    clouds:
        mycloud:
            auth:
                auth_url: http://theclowd.com:5000/v2.0
                username: cloud_user
                password: cloud_pass
                project_name: "My Cloud Project"

## Docker

ansible-cira also supports docker container instead of OpenStack and Vagrant.
In order to use docker, you need to insatll [docker-compose](https://docs.docker.com/compose/).

At present, we tested in docker-compose 1.7.1, build 6c289830.

# Overrides / Private Info

There may be some variables you don't want to expose into a Git repo. You can
store those in the `~/.ansible/vars/cira_vars.yml` file.

> **NOTE**: You *must* create a `~/.ansible/vars/cira_vars.yml` file, even if
> it is blank. This file is loaded via `var_files` directives in Ansible and
> your deployment will fail if the file doesn't exist.

The following list of options are required when deploying to an OpenStack
cloud:

**Cloud Configuration**
* cloud_name_prefix
* cloud_name
* cloud_region_name
* cloud_availability_zone
* cloud_image
* cloud_flavor
* cloud_key_name

The `jenkins_scp_sites` variable is required when you need to copy
configuration files off the slave to the master. Note that the hostname is
relative to the master (in this case, files are copied off the slave *into* the
master node, since that's where the SCP command is run).

**SCP Site Configuration**

    jenkins_scp_sites:
      - hostname: 127.0.0.1
        path: "{{ jenkins_master_results_directory }}"

When adding slaves, you would do so by creating a new file in the `hosts/`
directory. For example you would create a `hosts/slaves` file and add your
Jenkins slaves via the `[jenkins_slave]` and `[jenkins_slave:vars]` headers.

**Jenkins Slave Configuration**
* slave_name
* slave_description
* slave_remoteFS
* slave_host
* slave_port
* slave_credentialsId
* slave_label

## Example Override Variable File
Many of the values can be found in your OpenStack RC file, which can typically
be found in the _Access & Security_ section of the Horizon dashboard.

    cloud_name_prefix: redhat                  # virtual machine name prefix
    cloud_name: mycloud                        # same as specified in clouds.yml
    cloud_region_name: mycloud_region          # OS_REGION_NAME
    cloud_availability_zone: nova              # availability zone
    cloud_image: c0a97bbd-0cdd-4ed1-b6c1-052123456789    # unique image ID
    cloud_flavor: m1.medium
    cloud_key_name: my_pub_key                 # name of your keypair
 
    jenkins_job_builder_git_jobs_src: gitserver.tld:leifmadsen/nfv-jenkins-jobs.git   # branched from upstream for customization purposes
    jenkins_job_config_git_src: gitserver.tld:nfvpe/nfv-job-configs.git
    jenkins_job_builder_config_jenkins_user: admin       # default username
    jenkins_job_builder_config_jenkins_password: admin   # default password
 
    # Can only specify a single site to SCP files to at the end of the run.
    jenkins_scp_sites:
      - hostname: 127.0.0.1
        path: "{{ jenkins_master_results_directory }}"   # defined in vars/main.yml

# Deployment

Deployment can be done via two methods: OpenStack cloud, or Vagrant development
environment.

## Base Deployment (Vagrant)

Deploying into a Vagrant development environment should be as simple as
running:

    vagrant up

This will deploy all the virtual machines and apply the `site.yml` Ansible
configuration to the virtual machines. The deployment uses the built in default
networking configuration that Vagrant instantiates. At the end of the run, the
web interface addresses for Jenkins and Kibana will be displayed.

## Base Deployment (OpenStack)

You may need to modify the `host_vars/localhost` file to adjust the
`security_group` names, as the playbook does not currently create security
groups and rules for you. It is assumed you've created the following sets of
security groups, and opened the corresponding ports:

* default
  * `TCP: 22`
* elasticsearch
  * `TCP: 9200`
* filebeat-input
  * `TCP: 5044`
* web_ports
  * `TCP: 80, 443`

> **NOTE**: The security groups are only relevant for OpenStack cloud
> deployments. There are no firewall rules managed by CIRA within a Vagrant
> deployment.

The base set of four VMs created for the CI components in OpenStack are listed
as follows (as defined in `host_vars/localhost`):

    instance_list:
      - { name: elasticsearch, security_groups: "default,elasticsearch" }
      - { name: logstash, security_groups: "default,filebeat-input" }
      - { name: kibana, security_groups: "default,web_ports" }
      - { name: jenkins_master, security_groups: "default,web_ports" }

After configuration, you can run the following command which will connect to
localhost to run the `shade` applications, authenticate to the OpenStack API
you've supplied in `clouds.yml` and then deploy the stack.

    ansible-playbook site.yml

## Configure Jenkins plugins

In order to configure `scp` plugin, you'll need to use the `jenkins_scp_sites`
var. It expects a list of sites where Jenkins will copy the artifacts from
the jobs. The hostname / IP address should be relative to the Jenkins master
server, as that is where the SCP module will be executed.

Format is the following (see _Example Variable Override File_ for an example):

    jenkins_scp_sites:
      - hostname: test_hostname
        user: jenkins1
        password: abc
        path: /test/path
      - hostname: test_hostname
        port: 23
        user: jenkins1
        keyfile: abc
        path: /test/path

## Base Deployment (docker)

Start by creating `hosts/containers` (or similar) and add your baremetal machine
with the following template:

    jenkins_master
    logstash
    elasticsearch
    kibana

These name (e.g. jenkins_master, logstash...) should be matched with container name in cira-container.yml.

If you need to add jenkins slaves (baremetal), add slave information in 'hosts/containers'
as following (please add 'ansible_connection=ssh').

    [jenkins_slave]
    slave01 ansible_connection=ssh ansible_host=10.10.1.1 ansible_user=ansible

    [jenkins_slave:vars]
    slave_description=CIRA Testing Node
    slave_remoteFS=/home/stack
    slave_port=22
    slave_credentialsId=jenkins-credential
    slave_label=cira

Then, you can run following commands to setup containers and to setup cira environments.

    $ docker-compose up -d
    $ ansible-playbook site.yml -vvvv -i hosts/containers -e use_openstack_deploy=false -e deploy_type='docker' -c docker

After you finish, you can stop these containers and restart them.

    $ docker-compose stop
    (To restart them)
    $ docker-compose restart

The following commands deletes container.

    $ docker-compose down

### Jenkins Slave Installation

If you wish you automate the deployment of your Jenkins baremetal slave
machine, you can use Kickstart (or other similar methods). A base minimal
installation of a CentOS node, as booted from a cdrom (we're using CentOS as
booted from the vFlash partition on a DRAC) can be configured during boot by
pressing tab at the "Install CentOS" screen.

Add the following after the word `quiet` to statically configure a network and
boot from the `ks.cfg` file (as supplied in the `samples/` directory). You'll
need to host the `ks.cfg` file from a web server accessible from your Jenkins
baremetal slave node.

    ...quiet inst.ks=http://10.10.0.10/ks.cfg ksdevice=em1 ip=10.10.0.100::10.10.0.1:255.255.255.0:nfv-slave-01:em1:none nameserver=10.10.10.1

* `inst.ks`: Network path to the Kickstart file
* `ksdevice`: Device name to apply the network configuration to
* `ip`: Format is:  `[my_ip_address]::[gateway]:[netmask]:[hostname]:[device_name]:[boot_options]`
* `nameserver`: IP address of DNS nameserver

After booting, your machine should automatically deploy to a base minimum.

### Jenkins Slave Deployment

To deploy a Jenkins slave, you need to have a baremetal machine to connect to.
You can tell Ansible about this machine by creating a new inventory file in the
`hosts/` directory. You won't pollute the repository since all inventory files
except the `hosts/localhost` file as ignored.

Start by creating `hosts/slaves` (or similar) and add your baremetal machine
with the following template:

    [jenkins_slave]
    slave01 ansible_host=10.10.1.1 ansible_user=ansible
 
    [jenkins_slave:vars]
    slave_description=CIRA Testing Node
    slave_remoteFS=/home/stack
    slave_port=22
    slave_credentialsId=stack-credential
    slave_label=cira

Add additional fields if necessary. It is assumed that the `ansible` user has
been previously created, and that you can login either via SSH keys, or provide
the `--ask-pass` flag to your Ansible run. The `ansible` user is also assumed
to have been setup with passwordless sudo (unless you add `--ask-become-pass`
during your Ansible run).

[//]: # (vim: set filetype=markdown:expandtab)

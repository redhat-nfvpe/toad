# Deployment

Deployment can be done via two methods: stand-alone Docker or OpenStack cloud.

Additionally, you can kick off the deployment with the `./scripts/deploy.sh` which bootstraps a simple deployment 
using the stand-alone Docker method.

## Base Deployment

Start by creating `hosts/containers` (or similar) and add your baremetal machine
with the following template:

    jenkins_master
    logstash
    elasticsearch
    kibana

These names (e.g. jenkins_master, logstash, etc) should match the names as defined in `./docker-compose.yml`.

### Adding baremetal slaves to a Docker deployment

If you need to add jenkins slaves (baremetal), add slave information in `./hosts/containers`
as the following (be sure to add `ansible_connection=ssh` as well).

    [jenkins_slave]
    slave01 ansible_connection=ssh ansible_host=10.10.1.1 ansible_user=ansible

    [jenkins_slave:vars]
    slave_description=TOAD Testing Node
    slave_remoteFS=/home/stack
    slave_port=22
    slave_credentialsId=stack-credential
    slave_label=toad

### Running containers and start provisioning

Then, you can run the following commands to setup containers and to setup the TOAD environment.

    $ docker-compose up -d
    $ ansible-playbook site.yml -vvvv -i hosts/containers \
         -e use_openstack_deploy=false -e deploy_type='docker' -c docker

After you finish, you can stop these containers and restart them.

    $ docker-compose stop

Or, to restart the containers:

    $ docker-compose restart

The following command deletes the containers:

    $ docker-compose down

## Base Deployment (OpenStack)

> **NOTE**: Deploying directly to OpenStack virtual machines is deprecated. It is
> recommended that you perform a deployment using the Docker method (even if that is
> hosted in a cloud instance on OpenStack). In a future version this method may be
> removed.

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
> deployments.

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

### Jenkins Slave Installation

If you wish to automate the deployment of your Jenkins baremetal slave
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
    slave_description=TOAD Testing Node
    slave_remoteFS=/home/stack
    slave_port=22
    slave_credentialsId=stack-credential
    slave_label=toad

Add additional fields if necessary. It is assumed that the `ansible` user has
been previously created, and that you can login either via SSH keys, or provide
the `--ask-pass` flag to your Ansible run. The `ansible` user is also assumed
to have been setup with passwordless sudo (unless you add `--ask-become-pass`
during your Ansible run).

For OSP deployments, the build slaves need to be registered under RHN, and
repositories and guest images need to be synced locally. In order to enable
repository sync, you need to set the ``slave_mirror_sync`` var to ``true``.

> **NOTE**: By default, the system relies on the slave hostname and public IP
> to generate a valid repository address. Please ensure that slave hostname is
> set properly, and that is resolving to a public ip, reachable by all the VMs
> or baremetal servers involved in the deployments.

## Baremetal deployment

In order to perform baremetal deployments, an additional repository to host the
hardware environment configuration is needed. A sample repository is provided:
`https://github.com/redhat-nfvpe/toad_envs`

You can customize the repositories using the following settings:
- `jenkins_job_baremetal_env_git_src`: path to the repository where to host the
  environments
- `jenkins_job_baremetal_env_path`: if the environment is in a subfolder of the
  repo, please specify the relative path here.

The environment repo needs to have a folder for each environment that wants to
be tested. Each environment needs to have the following content:
- `deploy_config.yml`: it contains `extra_args` var, containing the
  parameters needed to deploy the overcloud. It specifies flavors, nodes to
  scale and templates to be used.
- `env_settings.yml`: TripleO quickstart environment settings for the baremetal
  deployment. It defines the network settings, undercloud configuration
  parameters and any additional settings needed.
- `instackenv.json`: Data file where all the baremetal nodes are specified. For
  each node, the IPMI address/user/password is required, as well as the
  provisioning MAC addresses.
- `net_environment.yml`: TripleO environment file that will be used. You can
  specify here all the typical TripleO settings that need to be customized.

## RHN subscription

On a Red Hat system, subscription of slaves can be managed automatically
if you pass the right credentials:
* `rhn_subscription_username`
* `rhn_subscription_password`
* `rhn_subscription_pool_id`

Subscription can be managed automatically either on master or slaves, with the
flags:
* `master_subscribe_rhn`
* `slave_subscribe_rhn`


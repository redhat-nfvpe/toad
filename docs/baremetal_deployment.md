Deploying to baremetal
====================

This document will cover how to do deployments on baremetal using **tripleo-quickstart**
When deploying to baremetal, there are two possible scenarios:

 1. both undercloud and overcloud are deployed on baremetal directly
 2. undercloud is virtualized and overcloud is deployed on baremetal

Case 2: virtualized undercloud, baremetal in overcloud
------------------------------------------------------------------------
The use case that is currently supported on **ansible-cira** is to have a virtualized undercloud, and a baremetal overcloud.

**Requirements**

To perform baremetal deployments, there are the following requirements:
 - One server for controller, one server for compute
 - Undercloud needs to be able to communicate with the ILO/IDRAC network, to manage boot and pxe on the baremetal servers
 - In the undercloud: two dedicated nics - one for ssh access to launch the build, another to deploy the control plane and communicate with baremetal servers
 - If using network isolation, 5 vlans: InternalApi, Storage, StorageManagement, External, Tenant

In terms of ansible roles, it needs a different set of requirements than TripleO quickstart. To consume them, please define
a quickstart-role-baremetla-requirements.txt file that will contain following dependencies:

- git+https://github.com/redhat-openstack/ansible-role-tripleo-cleanup-nfo.git/#egg=ansible-role-tripleo-cleanup-nfo
- git+https://github.com/redhat-openstack/ansible-role-tripleo-collect-logs.git/#egg=ansible-role-tripleo-collect-logs
- git+https://github.com/redhat-openstack/ansible-role-tripleo-gate.git#egg=ansible-role-tripleo-gate
- git+https://github.com/redhat-openstack/ansible-role-tripleo-overcloud.git#egg=ansible-role-tripleo-overcloud
- git+https://github.com/redhat-openstack/ansible-role-tripleo-overcloud-validate.git#egg=ansible-role-tripleo-overcloud-validate
- git+https://github.com/redhat-openstack/ansible-role-tripleo-overcloud-upgrade.git#egg=ansible-role-tripleo-overcloud-upgrade
- git+https://github.com/redhat-openstack/ansible-role-tripleo-overcloud-scale-nodes.git#egg=ansible-role-tripleo-overcloud-scale-nodes
- git+https://github.com/redhat-openstack/ansible-role-tripleo-undercloud-post.git/#egg=ansible-role-tripleo-undercloud-post

 
**Configuration**

CIRA relies on a config repo, that stores all private info for jobs to run. You can specify that repo using the ``jenkins_job_config_git_src`` parameter.
You can see a sample of job config repo at https://github.com/redhat-nfvpe/job-configs/. To enable hardware support, you need to create a
**hw_environments** folder inside your config repo, and create subfolders for each environment you need to deploy. Apart from hardware, you may need
to define network configuration, that needs to match the one on the lab you are going to use, and the extra requirements needed to support
baremetal deployment on TripleO Quickstart.

Each hardware environment needs the following content:

 - **instackenv.json:** ironic inventory with all the servers to be enrolled is defined here. It needs to follow that schema:

  {<br />
    "nodes": [<br />
      {<br />
        "mac": [<br />
          "mac-address"<br />
        ],<br />
        "cpu": "number-of-available-cpus",<br />
        "memory": "amount-of-memory-in-mb",<br />
        "disk": "amount-of-memory-in-gb",<br />
        "arch": "x864_64",<br />
        "pm_type": "pxe_ipmitool",<br />
        "pm_user": "ipmi_user",<br />
        "pm_password": "ipmi_pass",<br />
        "pm_addr": "ipmi_address"<br />
      }<br />
    ]<br />
  }<br />

 - **network_configs:** different kind of network configurations can be on that folder. In our case, we are starting with single_nic_vlans
 - **network_configs/single_nic_vlans:** subfolder containing all settings needed for that kind of network deployment on that hardware environment.
 - **network_configs/single_nic_vlans/env_settings.yml:** tripleo-quickstart configuration for that network deployment + hardware environment. Please refer to:
   - http://git.openstack.org/cgit/openstack/tripleo-quickstart/tree/roles/common/defaults/main.yml
   - http://git.openstack.org/cgit/openstack/tripleo-quickstart/tree/roles/tripleo/undercloud/templates/undercloud.conf.j2
   - https://github.com/redhat-openstack/ansible-role-tripleo-baremetal-prep-virthost/blob/master/defaults/main.yml

   It follows this schema:

   environment_type: name_of_your_hw_environment<br />
   hw_env: same<br />
   network_environment_file: "{{ lookup('env', 'WORKSPACE') }}/config/hw_environments/tef/network_configs/single_nic_vlans/single_nic_vlans.yml"<br />
   undercloud_network_cidr: 192.0.2.0/24<br />
   undercloud_external_network_cidr: 10.0.0.1/24<br />
   undercloud_network_gateway: 192.0.2.254<br />
   undercloud_local_interface: eth1<br />
   undercloud_masquerade_network: 192.0.2.0/24<br />
   virthost_provisioning_interface: eth1<br />
   virthost_provisioning_ip: 192.168.122.1<br />
   virthost_provisioning_netmask: 255.255.255.0<br />
   virthost_provisioning_hwaddr: ec:f4:bb:c0:b5:30<br />
   virthost_ext_provision_interface: em3<br />
   overcloud_nodes:<br />
   step_introspect: true<br />
   introspect: true<br />
   step_root_device_size: false<br />
   network_isolation_type: single_nic_vlans<br />
   network_isolation: true<br />
   floating_ip_cidr: 10.8.125.0/24<br />
   floating_ip_start: 10.8.125.161<br />
   floating_ip_end: 10.8.125.170<br />
   external_network_gateway: 10.8.125.254<br />

 - **network_configs/single_nic_vlans/single_nic_vlans.yml:** This is the file referenced by network_environment file. It contains the TripleO configuration for
  the overcloud deployment, specifically for our hardware and network environment. Please refer to 
  http://git.openstack.org/cgit/openstack/tripleo-heat-templates/tree/environments/network-environment.yaml.


 - **network_configs/single_nic_vlans/requirements_files/baremetal-virt-undercloud.txt:** This will allow to bring all the specific ansible roles needed for baremetal deployment.
   There can be custom roles for preparing the virtualized environment, deploying overcloud, etc... A sample requirements file looks like:

   git+https://github.com/redhat-openstack/ansible-role-tripleo-validate-ipmi.git/#egg=ansible-role-tripleo-validate-ipmi<br />
   git+https://github.com/redhat-openstack/ansible-role-tripleo-baremetal-overcloud.git/#egg=ansible-role-tripleo-baremetal-overcloud<br />
   git+https://github.com/redhat-openstack/ansible-role-tripleo-baremetal-prep-virthost/#egg=ansible-role-tripleo-baremetal-prep-virthost<br />
   git+https://github.com/redhat-openstack/ansible-role-tripleo-overcloud/#egg=ansible-role-tripleo-overcloud<br />

**How to run the baremetal job**

A final TripleO Quickstart deployment with baremetal follows the same process as a virtualized one, but adding extra configs and
requirements. A sample call will look like:

git clone https://git.openstack.org/openstack/tripleo-quickstart.git<br />
cd tripleo-quickstart<br />
export VIRTHOST=127.0.0.2<br />
export HW_ENV_DIR=${WORKSPACE}/config/hw_environments/tef<br /><br />
sudo bash ./quickstart.sh --install-deps<br />
bash quickstart.sh \<br />
--working-dir /home/jenkins/quickstart \<br />
--bootstrap \<br />
--tags all \<br />
--skip-tags overcloud-validate \<br />
--no-clone \<br />
--teardown all \<br />
--requirements ${WORKSPACE}/config/requirements/quickstart-role-baremetal-requirements.txt \<br />
--requirements $HW_ENV_DIR/network_configs/single_nic_vlans/requirements_files/baremetal-virt-undercloud.txt \<br />
--config $HW_ENV_DIR/network_configs/single_nic_vlans/config_files/config.yml \<br />
--extra-vars @$HW_ENV_DIR/network_configs/single_nic_vlans/env_settings.yml \<br />
--playbook baremetal-virt-undercloud-tripleo.yml \<br />
--extra-vars undercloud_instackenv_template=$HW_ENV_DIR/instackenv.json \<br />
--extra-vars network_environment_file=$HW_ENV_DIR/network_configs/single_nic_vlans/single_nic_vlans.yml \<br />
--extra-vars nic_configs_dir=$HW_ENV_DIR/network_configs/single_nic_vlans/nic_configs/ \<br />
--extra-vars jenkins_workspace=${WORKSPACE} \<br />
--release mitaka \<br />
$VIRTHOST

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
 
**Configuration**

The baremetal deployments are based on the concept of **hardware_environment**. A hardware environment defines the set of servers and network environment where a baremetal test is run.
There should be one hardware environment per partner/lab and they are defined at https://gitlab.cee.redhat.com/nfvpe/nfv-job-configs , inside **hw_environments** folder.

Each hardware environment needs the following content:

 - **instackenv.json:** ironic inventory with all the servers to be enrolled is defined here. It needs to follow that schema:

>
> {
>
>     "nodes": [
>
>         {
>
>             "mac": [
>
>                 "mac-address"
>
>             ],
>
>             "cpu": "number-of-available-cpus",
>
>             "memory": "amount-of-memory-in-mb",
>
>             "disk": "amount-of-memory-in-gb",
>
>             "arch": "x864_64",
>
>             "pm_type": "pxe_ipmitool",
>
>             "pm_user": "ipmi_user",
>
>             "pm_password": "ipmi_pass",
>
>             "pm_addr": "ipmi_address"
>
>         }
>
>     ]
>
> }


 - **network_configs:** different kind of network configurations can be on that folder. In our case, we are starting with single_nic_vlans
 - **network_configs/single_nic_vlans:** subfolder containing all settings needed for that kind of network deployment on that hardware environment.
 - **network_configs/single_nic_vlans/env_settings.yml:** tripleo-quickstart configuration for that network deployment + hardware environment. Please refer to http://git.openstack.org/cgit/openstack/tripleo-quickstart/tree/roles/tripleo/overcloud/defaults/main.yml
 - network_configs/single_nic_vlans/single_nic_vlans.yml: TripleO configuration for the overcloud deployment, for that network deployment + hardware environment. Please refer to http://git.openstack.org/cgit/openstack/tripleo-heat-templates/tree/environments/network-environment.yaml
 - **network_configs/single_nic_vlans/requirements_files/baremetal-virt-undercloud.txt:** This will allow to bring all the specific ansible roles needed for baremetal deployment. There can be custom roles for preparing the virtualized environment, deploying overcloud, etc...

These settings can be picked by jobs defined at https://gitlab.cee.redhat.com/nfvpe/nfv-jenkins-jobs to perform baremetal deployments based on **TripleO Quickstart**.

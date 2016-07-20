# ansible-cira

Deploy a continuous integration reference architecture with Jenkins to test
OpenStack with [TripleO
Quickstart](https://github.com/openstack/tripleo-quickstart).


## Requirements

You'll need to install the `shade` dependency so that you can interact with
OpenStack (assuming you are deploying to an OpenStack cloud).

    pip install --user shade

For Ansible, several roles are required, and you can install them as follows:

    ansible-galaxy install -r requirements.yml

## Setup OpenStack Connection

If you're going to install to an OpenStack cloud, you'll need to configure a
cloud to connect to. You can do this by creating the `~/.config/openstack/`
directory and placing the following contents into the `cloud.yml` file within
that directory (adjust to your own cloud connection):

    clouds:
        mycloud:
            auth:
                auth_url: http://theclowd.com:5000/v2.0
                username: cloud_user
                password: cloud_pass
                project_name: "My Cloud Project"

## Overrides / Private Info

There may be some variables you don't want to expose into a Git repo. You can
store those in the `~/.ansible/vars/cira_vars.yml` file. For example, the
following variables are being utilized by the author:

* cloud_name_prefix
* cloud_name
* cloud_region_name
* cloud_availability_zone
* cloud_image
* cloud_flavor
* cloud_key_name
* jenkins_job_builder_git_jobs_src

## Deployment

You may need to adjust the `host_vars/localhost` file to adjust the
`security_group` names, as the playbook does not currently create security
groups and rules for you. It is assumed you've created the following sets of
security groups, and opened the corresponding ports:

* elasticsearch
  * `TCP: 9200`
* filebeat-input
  * `TCP: 5440`
* web_ports
  * `TCP: 80, 443`

After configuration, you can run the following comment which will connect to
localhost to run the `shade` applications, authenticate to the OpenStack API
you've supplied in `cloud.yml` and then deploy the stack.

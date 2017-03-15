# Requirements

TOAD is generally deployed in Docker containers. You can choose to deploy using
Docker, or, together with an existing OpenStack deployment. Below you will find
the list of requirements for each of the deployment scenarios.

For Ansible, several roles are required, and you can install them as follows:

    ansible-galaxy install -r requirements.yml

## Docker

TOAD primarily utilizes Docker containers. In order to use Docker, you need to
install [docker-compose](https://docs.docker.com/compose/).

At present, our `docker-compose` YAML file uses the version 2 specification,
and should work with docker-compose version 1.6.0 or greater, and Docker engine
1.10.0 or later.

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


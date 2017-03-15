# Quickstart

If you're on a Fedora 25 (or later) or CentOS 7.3 system, and you're ok with
running a bash script as root, you can bootstrap your system with the following
command:

    curl -sSL http://bit.ly/toad-bootstrap | sh

After bootstrapping your machine, you can perform an "all in one" Jenkins
Master/Slave deployment with the following command:

    su - toad
    curl -sSL http://bit.ly/toad-deploy | sh

## All In One Deployment

With the _All In One_ (AIO) deployment, a Jenkins Master will be instantiated
via Docker Compose and configured via Ansible. A Jenkins Slave will then be
added to the Jenkins Master by logging into the virtual host that hosts the
Docker containers (including the Jenkins Master).

![TOAD All In One][toad_aio_overview]

For an AIO deployment, you first bootstrap the node and then deploy the
contents of TOAD onto the virtual host (see [Quickstart](#quickstart)). After
instantiating your Jenkins Master via Docker Compose, it is configured via
Ansible.

During the Ansible run in the `deploy.sh` script, it will also deploy a Jenkins
Slave from the Master. The host for the Slave is the virtual host itself, and
this is done via the `toad_default` Docker network.

    [toad@virthost toad]$ docker network ls
    NETWORK ID          NAME                DRIVER              SCOPE
    a21540f49541        bridge              bridge              local
    9fc7cb193fbb        host                host                local
    9db741f62407        none                null                local
    0e51b147a044        toad_default        bridge              local

If we inspect this Docker network, we can see our Jenkins Master network
address and the address of the gateway (our virtual host).

    [toad@virthost toad]$ docker network inspect toad_default
    [
        {
            "Name": "toad_default",
            "Id": "0e51b147a04426dbff8c27ff4205d6487c3fec8a1b1e764cac68d30ffdfd9104",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "IPAM": {
                "Driver": "default",
                "Options": null,
                "Config": [
                    {
                        "Subnet": "172.18.0.0/16",
                        "Gateway": "172.18.0.1/16"
                    }
                ]
            },
            "Internal": false,
            "Containers": {
                "7e8bfdc51266955b8efcb7909ed5e130206e3dd8c791b8660a90ef7bb25f8c0b": {
                    "Name": "jenkins_master",
                    "EndpointID": "abe24ce17a677b0f73bed5672ba96145c012236cda16459f2bebc3c429cb6283",
                    "MacAddress": "02:42:ac:12:00:03",
                    "IPv4Address": "172.18.0.3/16",
                    "IPv6Address": ""
                },
            "Options": {},
            "Labels": {}
        }
    ]

The Jenkins Master will then SSH from `172.18.0.3` into the virtual host via
the `toad_default` bridge through the gateway, and configure it as a Jenkins
Slave. The Jenkins Slave will be used to execute the Jenkins jobs that we've
configured via JJB (Jenkins Job Builder), which will run the TripleO
`quickstart.sh` script.

> **NOTE**: The bridges created by Docker are dynamically named. You can link
> the bridge name in Linux to the Docker bridge by looking at the `ID` field in
> the `docker network inspect` output, by taking the first 12 characters, and
> comparing that to the bridge names output by running `brctl show` or `ip a s`

The TripleO quickstart script will then setup an undercloud, controller, and
compute node (by default, the `minimal.yml` configuration) via libvirt on the
virtual host. The connection to the undercloud is made via the `brext` bridge,
which is configured under libvirt as the `external` bridge. More information
about the `external` bridge can be seen by running `virsh net-dumpxml
external`:

    [toad@virthost toad]$ sudo virsh net-dumpxml external
    <network>
      <name>external</name>
      <uuid>c0adf892-1961-486c-b565-b26efafc3fe1</uuid>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='brext' stp='off' delay='0'/>
      <mac address='52:54:00:2e:81:c1'/>
      <ip address='192.168.23.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.23.10' end='192.168.23.50'/>
        </dhcp>
      </ip>
    </network>

Triple quickstart will also create another bridge called `brovc` for the
communication between the undercloud and the overcloud. In libvirt it is
configured as the `overcloud` network:

    [toad@virthost toad]$ sudo virsh net-dumpxml overcloud
    <network>
      <name>overcloud</name>
      <uuid>b21fa3cf-bd62-4d49-9856-768d8a8e4100</uuid>
      <bridge name='brovc' stp='off' delay='0'/>
      <mac address='52:54:00:db:6b:51'/>
    </network>

That should give you an idea of how TOAD performs an AIO installation on a
single network node. You'll need a fairly robust machine for this type of setup
though. It is recommended that you use a machine with at least 32GB of RAM,
ideally 64GB of RAM.

[toad_aio_overview]: toad_aio_overview.png

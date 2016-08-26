Creating custom images
======================
This document will cover how to create custom images to be used in **tripleo-quickstart**. Undercloud, overcloud and initramfs images can be customized.

Requirements
------------
You will need a virtual machine or an static server where to run the image builds. The image builds need to have a pre-existing image as a base, that needs to exist on your system, in **qcow2** format.
It depends on https://github.com/redhat-openstack/ansible-role-tripleo-parts.git and https://github.com/redhat-openstack/ansible-role-tripleo-image-build.git , that are the roles that perform the image builds.
Please note that image building performance will be better on a baremetal host, where available memory is an important fact.

Configuration
-------------
The image build can be configured as a simple jenkins job. You can see the definitions on https://gitlab.cee.redhat.com/nfvpe/nfv-jenkins-jobs repository. The job build will install the mentioned repositories, and call the image build playbook with the specified settings. You can refer to documentation for **ansible-role-tripleo-image-build** for extensive documentation.

The build config files are on https://gitlab.cee.redhat.com/nfvpe/nfv-job-configs repository, under the **build** folder. There will be a config file per release/partner. A sample config file can have the following format:

artib_base_os: rhel7
artib_build_system: delorean
artib_minimal_base_image_url: file:///opt/rhel-guest-image-7.2-20160302.0.x86_64.qcow2
artib_release: liberty
artib_repo_script: "{{ jenkins_workspace }}/config/scripts/repo_setup_rhel_osp8_nokia.j2"
artib_undercloud_convert_script:  "{{ jenkins_workspace }}/config/scripts/undercloud_convert_rhel_osp.j2"
artib_working_dir: "{{ jenkins_workspace }}/oooq-images"
artib_package_install_script: "{{ jenkins_workspace }}/config/scripts/nokia-package-install.sh.j2"
publish: false
undercloud_image_url: "file:///{{ jenkins_workspace }}/oooq-images/undercloud.qcow2"
artib_dib_elements_path:
  - /usr/share/tripleo-image-elements
  - /usr/share/tripleo-puppet-elements
  - /usr/share/instack-undercloud/
  - /usr/share/openstack-heat-templates/software-config/elements/
  - /opt/cbis-dib/usr/share/diskimage-builder/elements
artib_image_yaml_template: "{{ jenkins_workspace }}/config/templates/nokia-dib-manifest-default.yaml.j2"

These options are documented on the image building role properly. See that some options are pointing to scripts or templates inside that config folder. Because of that, in **nfv-job-configs** repository, there are two additional **scripts** and **templates** folder where you can create all the extra scripts and templates you need for your configuration. The naming of these scripts shall contain references about release and partner for easier understanding.

How images are built
--------------------
The process for building images is the following:

1. Retrieves the base image for builds, that is specified in **artib_minimal_base_image_url** and can point to a file on the same server, or to a remote url.
2. Installs extra repositories that will be available on all images. That allows to point to a custom script, where additional repos can be defined or not needed one can be disabled, using the **artib_repo_script** var
3. Starts working on building overcloud, using previous image as base. Installs any extra package needed in the overcloud, using virt-customize. This can be used to install any package that will be needed, using the **artib_package_install_script** var
4. Starts working on the undercloud. To do that, normally overcloud image is used as base, but a custom one can be specified using **artib_undercloud_base_image_url** var
5. Using that undercloud image as base, resize it properly using virt-customize, and apply any extra conversion tasks needed, using **artib_undercloud_convert_script** file. The usual steps for conversion, is to apply growfs, remove/install packages, and add extra users, keys and hosts entries.
6. Start working on overcloud-full image creation. This will contain overcloud image, and initramfs ones. This job will be done with diskimage-builder, and will rely on a manifest that will indicate all DIB settings needed.
7. Execute any previous customizations needed prior to run diskimage-builder. Using overcloud-base image, it will run an script specified by *artib_dib_workaround_script* on it. This is useful for last-minute fixes in python script, config changes, etc...
8. Run the main diskimage-builder process, that will generate the overcloud-full images. Ramdisk will be created using the **artib_minimal_base_image_url** image and overcloud will be created using the **overcloud-base** image. The manifest template can be customized and is specified on **artib_image_yaml_template** var
9. You can see a sample manifest on https://github.com/redhat-openstack/ansible-role-tripleo-image-build/blob/master/templates/dib-manifest-default.yaml.j2 . See the two image definitions there: **ironic-python-agent** and **overcloud-full**. Each bit allows to customize the diskimage creation process as usual: elements, packages to install, env vars , base distro, extra options.
10. When the image creation process has completed, it should have generated the **ironic-python-agent.initramfs** , **ironic-python-agent.kernel** , **overcloud-full.initrd**, **overcloud-full.qcow2** and **overcloud-full.vmlinuz** artifacts. These will be injected into undercloud using virt-customize.
11. After all this process has finished, images are compressed and archived properly, being published to the final directory that is specified on the job.


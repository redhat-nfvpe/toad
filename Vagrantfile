# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.define :jenkins_master do |jenkins_master|
    jenkins_master.vm.box = "centos/7"
    jenkins_master.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "2048"
    end
  end

  config.vm.define :elasticsearch do |elasticsearch|
    elasticsearch.vm.box = "centos/7"
    elasticsearch.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "1024"
    end
  end

  config.vm.define :logstash do |logstash|
    logstash.vm.box = "centos/7"
    logstash.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "1024"
    end
  end

  config.vm.define :kibana do |kibana|
    kibana.vm.box = "centos/7"
    kibana.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "2048"
    end
  end

  config.vm.provision :ansible do |ansible|
    ansible.extra_vars = {
      use_openstack_deploy: false,
      vars_files_relative: "../../../.."    # this sets the relative path from
                                            # from the inventory file to the
                                            # vars/ directory.
    }
    ansible.limit = "all"
    ansible.skip_tags = "jenkins_slave"
    ansible.playbook = 'site.yml'
  end
end

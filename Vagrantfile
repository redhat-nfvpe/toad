# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.define :elasticsearch do |elasticsearch|
    elasticsearch.vm.box = "centos/7"
    elasticsearch.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "1024"
    end

    # load in custom configuration for elasticsearch if it exists
    elasticsearch_vagrantfile = File.expand_path('../vagrant/Vagrantfile.elasticsearch',__FILE__)
    eval File.read(elasticsearch_vagrantfile) if File.exists?(elasticsearch_vagrantfile)
  end

  config.vm.define :logstash do |logstash|
    logstash.vm.box = "centos/7"
    logstash.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "1024"
    end

    # load in custom configuration for logstash if it exists
    logstash_vagrantfile = File.expand_path('../vagrant/Vagrantfile.logstash',__FILE__)
    eval File.read(logstash_vagrantfile) if File.exists?(logstash_vagrantfile)
  end

  config.vm.define :kibana do |kibana|
    kibana.vm.box = "centos/7"
    kibana.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "2048"
    end

    # load in custom configuration for kibana if it exists
    kibana_vagrantfile = File.expand_path('../vagrant/Vagrantfile.kibana',__FILE__)
    eval File.read(kibana_vagrantfile) if File.exists?(kibana_vagrantfile)
  end

  config.vm.define :jenkins_master do |jenkins_master|
    jenkins_master.vm.box = "centos/7"

    jenkins_master.vm.provider :libvirt do |domain|
      domain.machine_arch = 'x86_64'
      domain.cpu_mode = 'host-passthrough'
      domain.memory = "2048"
    end

    # load in custom configuration for jenkins_master if it exists
    jenkins_master_vagrantfile = File.expand_path('../vagrant/Vagrantfile.jenkins_master',__FILE__)
    eval File.read(jenkins_master_vagrantfile) if File.exists?(jenkins_master_vagrantfile)

    jenkins_master.vm.provision "ansible", run: "never" do |ansible|
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
end

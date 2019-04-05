# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "genebean/centos-7-puppet-latest"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 9443

  config.vm.provision "shell", inline: <<-SHELL1
    yum upgrade -y
    yum install -y centos-release-scl 
    yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
    puppet module install puppetlabs-apache
    puppet module install puppet-php
    puppet apply /vagrant/manifests/site.pp
  SHELL1
end

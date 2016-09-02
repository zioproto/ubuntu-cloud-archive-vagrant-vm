# -*- mode: ruby -*-
# vi: set ft=ruby :

# This ubuntu/xenial64 is broken ! At the first boot provision will fail.
# Do a vagrant ssh and install the following:
# sudo apt-get --no-install-recommends install virtualbox-guest-utils
# then get out and reboot with vagrant halt && vagrant up
# Or you can just install this plugin:
# vagrant plugin install vagrant-vbguest

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.synced_folder ".", "/vagrant/" # fix broken ubuntu/xenial64 image
  config.vm.provider "virtualbox" do |vb|
     vb.cpus = "2"
     vb.memory = "2048"
  # Remember to `ssh-add` before `vagrant ssh`
  config.ssh.forward_agent = true
  end
end

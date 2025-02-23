# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # use official ubuntu image for virtualbox
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.box = "ubuntu/focal64"
    override.vm.synced_folder ".", "/srv/aquagis-api"
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  # Use sshfs sharing if available, otherwise NFS sharing
  sharing_type = Vagrant.has_plugin?("vagrant-sshfs") ? "sshfs" : "nfs"

  # use third party image and sshfs or NFS sharing for lxc
  config.vm.provider "lxc" do |_, override|
    override.vm.box = "generic/ubuntu2004"
    override.vm.synced_folder ".", "/srv/aquagis-api", :type => sharing_type
  end

  # use third party image and sshfs or NFS sharing for libvirt
  config.vm.provider "libvirt" do |_, override|
    override.vm.box = "generic/ubuntu2004"
    override.vm.synced_folder ".", "/srv/aquagis-api", :type => sharing_type
  end

  # configure shared package cache if possible
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.enable :apt
    config.cache.scope = :box
  end

  # port forward for webrick on 3000
  config.vm.network :forwarded_port, :guest => 3000, :host => 3700
  config.vm.network :forwarded_port, :guest => 5432, :host => 5499

  # provision using a simple shell script
  config.vm.provision :shell, :path => "script/vagrant/setup/provision.sh"
end

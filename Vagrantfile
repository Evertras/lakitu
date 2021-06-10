# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use the bento version because it's considered friendlier for multiple
  # providers compared to the "official" ubuntu version
  config.vm.box = "bento/ubuntu-20.10"

  # This is the main host where we run servers/etc
  config.vm.define "lakitu", primary: true do |lakitu|
    lakitu.vm.hostname = "lakitu"
    lakitu.vm.network "private_network", ip: "192.168.3.2"
  end

  # These are agent servers that run things that connect to the main host
  config.vm.define "spiney1" do |spiney1|
    spiney1.vm.hostname = "spiney1"
    spiney1.vm.network "private_network", ip: "192.168.3.3"
  end
  config.vm.define "spiney2" do |spiney2|
    spiney2.vm.hostname = "spiney2"
    spiney2.vm.network "private_network", ip: "192.168.3.4"
  end
end

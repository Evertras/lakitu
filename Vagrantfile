# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use the bento version because it's considered friendlier for multiple
  # providers compared to the "official" ubuntu version
  config.vm.box = "bento/ubuntu-20.10"

  # This is the main host where we run servers/etc
  config.vm.define "lakitu", primary: true do |lakitu|
    lakitu.vm.hostname = "lakitu"
    lakitu.vm.network "private_network", ip: "192.167.3.2"
  end

  # This is an agent server that runs things that connect to the main host
  config.vm.define "spiney1" do |spiney1|
    spiney1.vm.hostname = "spiney1"
    spiney1.vm.network "private_network", ip: "192.167.3.3"
  end
end

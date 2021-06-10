# Lakitu

A playground for tiny virtual cloud things.  Intended to be a personal reference
and for playing with various cloud-y tools in a repeatable way.

This will not contain any AWS/GCP/Azure/etc. things, but rather focuses on tools
and products that get installed on infrastructure and Ansible to maintain them.

## Requirements

* Makefile
* [Python 3.9.5](https://github.com/pyenv/pyenv)
* [Vagrant](https://www.vagrantup.com/downloads) (See below for why)

## Techs used + Reasoning

### Vagrant

[Hashicorp Vagrant](https://vagrantup.com) is a way to repeatably bring up full
VMs with a single config file.

This is used to bring up local VMs to play with to emulate a cloud without having
to actually create any costly resources.

Note that we can't vendor this tool because Vagrant's install process also helps
set up a virtual machine provider.  [Check the Vagrant downloads page](https://www.vagrantup.com/downloads)
for proper instructions on installing Vagrant.


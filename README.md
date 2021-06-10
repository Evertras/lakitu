# Lakitu

A playground for tiny virtual cloud things.  Intended to be a personal reference
and for playing with various cloud-y tools in a repeatable way.

This will not contain any AWS/GCP/Azure/etc things, but rather focuses on tools
and products that get installed on infrastructure and Ansible to maintain them.

## Requirements

* Makefile
* [Python 3.9.5](https://github.com/pyenv/pyenv)
* [Vagrant](https://www.vagrantup.com/downloads) (See below for why)

Everything else should be installed through the Makefile in a local scope only.

## Running it

```bash
# Start the machines
vagrant up

# Apply the Ansible roles
make ansible-apply

# Try a sample Nomad job
./bin/nomad run samples/hello-world.nomad

# Check the output to see which host it ran on
./bin/nomad status hello
./bin/nomad alloc logs abcdef hostname

# Tear everything down
vagrant destroy -f
```

## Techs used + Reasoning

### Vagrant

[Hashicorp Vagrant](https://vagrantup.com) is a way to repeatably bring up full
VMs with a single config file.

This is used to bring up local VMs to play with to emulate a cloud without having
to actually create any costly resources.

Note that we can't vendor this tool because Vagrant's install process also helps
set up a virtual machine provider.  [Check the Vagrant downloads page](https://www.vagrantup.com/downloads)
for proper instructions on installing Vagrant.

### Ansible

We use [Ansible](https://ansible.com) to configure our machines.  Note that Vagrant
[has an Ansible provisioner](https://www.vagrantup.com/docs/provisioning/ansible)
but we're actively choosing not to use it.  Instead we want to manually set up
our Ansible purely for practice/simplicity.  The point is to play with Ansible
as if we were targeting regular machines that live somewhere else.

Ansible is installed via the Makefile using a Python virtual environment.


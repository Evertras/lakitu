# Lakitu

A playground for tiny virtual cloud things.  Intended to be a personal reference
and for playing with various cloud-y tools in a repeatable way.

This will not contain any AWS/GCP/Azure/etc things, but rather focuses on tools
and products that get installed on infrastructure and Ansible to maintain them.

## Requirements

The following must be explicitly installed on the host machine.

* Makefile
* [Python 3.9.5](https://github.com/pyenv/pyenv)
* [Vagrant](https://www.vagrantup.com/downloads) (See below for why)

Everything else should be installed through the Makefile in a local scope only.

This is being developed on a mac, but should also work fine on Linux.

### Direnv

[Direnv](https://github.com/direnv/direnv) allows us to set local environment
files and add to our path while working within this repository.

[A sample .envrc file](./envrc.example) has been added for reference.  Direnv
is not strictly necessary, but it will make playing around with CLI tools against
the cluster much, much easier.

## Running it

Check the Makefile for some more commands to run, but here's the starting idea.
Note that this assumes you have `direnv` enabled and a `.envrc` the same as
the example; otherwise you'll need to set these yourself and use `./bin/nomad`
and `./bin/consul` directly.

```bash
# Start the machines
vagrant up

# Quick sanity check to see if we can reach our hosts
make ansible-ping

# Apply the Ansible roles
make ansible-apply

# Sanity check Nomad - should see the spineys ready after a short time
nomad node status

# Sanity check Consul - should see all hosts as members
consul members

# You can check the Consul UI here:
open http://192.168.3.2:8500/ui

# Try a sample Nomad job - note this uses the values in .envrc.example to point
# to the cluster and use our local Nomad CLI binary.  If you don't use direnv,
# you should set NOMAD_ADDR and use ./bin/nomad instead.
nomad run samples/hello-world.nomad

# Check the output to see which host it ran on
nomad status hello
nomad alloc logs abcdef hostname

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

### Nomad

[Hashicorp Nomad](https://nomadproject.io) runs various arbitrary workloads
and allows us to connect our machines together in a cluster where we can run
various things.  This is nicer than Kubernetes in this particular case because
we can run things directly on the VM itself.

### Consul

[Hashicorp Consul](https://www.consul.io) is service mesh, networking thing that
Nomad uses to coordinate itself.  Mostly I just want to actually learn to use
Consul in a sandbox area to see what it can really do.

### Vault

[Hashicorp Vault](https://www.vaultproject.io/) is a secrets management tool
that we can use for storing and retrieving secrets.  Since we're already going
full Hashicorp, let's use Vault for easier integration to handle our secrets
such as credentials.

## Users

A sample set of users and user management is added.  The intent is for the users
to provide a public key, or they can have their keys generated.  Since this is
just a demo, the keys must be generated.  In a real setup, the registered public
keys should be checked into git, and the private keys should be stored
elsewhere.

This setup uses the user name to look for the SSH key.  Only the public key must
exist for the playbook to be run, and it must be placed in
`ansible/keys/public/<username>.pub`.  The private keys are generated on the fly
purely for demonstration purposes and do not necessarily need to live in the
private folder.

```bash
# Regenerate all user keys
make regen-keys

# Apply the keys and user status
make users
```

To SSH in as one of the users, run:

```bash
# SSH into spiney1 as Mario
ssh -i ansible/keys/private/mario mario@192.168.56.3
```

## Various TODOs

In no particular order and not an exclusive list, just jotting things down here.

* Pin ansible version in virtualenv
* Put Consul encryption into Vault
* Add Minio
* Add some microservices via Nomad + Consul discovery
* Figure out whether x.service should be in x-server or x (Nomad/Consul)
* RPC encryption for Consul
* Create multiple lakitus to make a real clustered server plane
* Play with Consul templating
* Consul auth for API/CLI from host machine
* Better system for Consul cert generation, this is currently fragile/bleh


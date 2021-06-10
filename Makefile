# Which version of Nomad to put on the machines and have locally
NOMAD_VERSION := 1.1.1

# Install things and make sure we have everything we need
.PHONY: ensure-env
ensure-env: ensure-python .venv/bin/ansible
	@echo Ready to go!

# Make sure "python" points to 3.9.5 version to make sure pyenv is in effect
# and that we have the latest Python for the latest Ansible version to use
.PHONY: ensure-python
ensure-python:
	@test $(shell python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))') == "3.9.5" || \
		(echo "ERROR: Python version must be 3.9" && exit 1)

# Makes sure all services are installed/running
.PHONY: ansible-apply
ansible-apply: .venv/bin/ansible ansible/roles/nomad/files/nomad bin/nomad
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml playbook.yaml

# Forces a restart of all the Nomad services
.PHONY: ansible-restart-nomad
ansible-restart-nomad: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml restart-nomad.yaml

# Stops any running Nomad services and deletes all the data directories.
# Useful to reset to a fresh state without destroying/recreating everything.
.PHONY: ansible-delete-nomad-data
ansible-delete-nomad-data: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml delete-nomad-data.yaml

# Quick ping to all hosts to make sure the inventory is valid and all our hosts exist
.PHONY: ansible-ping
ansible-ping: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible -m ping -i inventory.yaml all

# Clean any auto-generated things or downloaded dependencies
.PHONY: clean
clean:
	rm -rf .venv
	rm -rf bin
	rm ansible/roles/nomad/files/nomad

# Local pip
.venv/bin/pip:
	python -m venv .venv

# Local ansible
.venv/bin/ansible: .venv/bin/pip
	./.venv/bin/pip install ansible

# For now we only support Linux 64 bit and MacOS
ifeq ($(shell uname), Darwin)
OS_URL := darwin
else
OS_URL := linux
endif

# Local Nomad
bin/nomad:
	@mkdir -p bin
	curl -o bin/nomad.zip \
		https://releases.hashicorp.com/nomad/$(NOMAD_VERSION)/nomad_$(NOMAD_VERSION)_$(OS_URL)_amd64.zip
	@cd bin && unzip nomad.zip
	@rm bin/nomad.zip

# Nomad for the Linux VMs
ansible/roles/nomad/files/nomad:
	curl -o ansible/roles/nomad/files/nomad.zip https://releases.hashicorp.com/nomad/$(NOMAD_VERSION)/nomad_$(NOMAD_VERSION)_linux_amd64.zip
	cd ansible/roles/nomad/files && unzip nomad.zip && rm nomad.zip


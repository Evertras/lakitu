# Which versions of various tools to both put on the machines and have locally
NOMAD_VERSION := 1.3.5
CONSUL_VERSION := 1.9.6
VAULT_VERSION := 1.7.2
WANDER_VERSION := 0.8.1

DC := mushroom-kingdom

# The certs will begin at 0, so a value of "3" will create 4 certs
CONSUL_CERT_SERVER_LAST_INDEX := 0

# Install things and make sure we have everything we need
.PHONY: ensure-env
ensure-env: ensure-python .venv/bin/ansible
	@echo Ready to go!

# Consistent formatting
.PHONY: fmt
fmt: node_modules
	npx prettier --write .

# Makes sure all services are installed/running
.PHONY: ansible-apply
ansible-apply: \
	.venv/bin/ansible \
	ansible/roles/consul/files/certs/consul-agent-ca.pem \
	ansible/roles/consul/files/certs/$(DC)-server-consul-$(CONSUL_CERT_SERVER_LAST_INDEX).pem \
	ansible/roles/consul/files/consul \
	ansible/roles/consul/vars/main.yaml \
	ansible/roles/nomad/files/nomad \
	ansible/roles/vault/files/vault \
	bin/consul \
	bin/nomad \
	bin/wander \
	bin/vault

	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml playbook.yaml

# Apply users
.PHONY: users
users: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml users.yaml

# Apply weave
.PHONY: weave
weave: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml weave.yaml

# Generate missing user keys
.PHONY: user-keys
user-keys: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml user-keys.yaml

# Regenerate all user keys, for testing/dev purposes
.PHONY: regen-keys
regen-keys: .venv/bin/ansible
	@rm -f ansible/keys/public/*.pub
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml user-keys.yaml

# Forces a restart of all the Nomad services
.PHONY: ansible-restart-nomad
ansible-restart-nomad: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml restart-nomad.yaml

# Forces a restart of all the Consul services
.PHONY: ansible-restart-consul
ansible-restart-consul: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible-playbook -i inventory.yaml restart-consul.yaml

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
clean: clean-consul-certs
	rm -rf .venv/
	rm -rf bin/
	rm -f ansible/roles/consul/files/consul
	rm -f ansible/roles/consul/vars/main.yaml
	rm -f ansible/roles/nomad/files/nomad
	rm -f ansible/roles/vault/files/vault

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

# Local Consul
bin/consul:
	@mkdir -p bin
	curl -o bin/consul.zip \
		https://releases.hashicorp.com/consul/$(CONSUL_VERSION)/consul_$(CONSUL_VERSION)_$(OS_URL)_amd64.zip
	@cd bin && unzip consul.zip
	@rm bin/consul.zip

# Local Vault
bin/vault:
	@mkdir -p bin
	curl -o bin/vault.zip \
		https://releases.hashicorp.com/vault/$(VAULT_VERSION)/vault_$(VAULT_VERSION)_$(OS_URL)_amd64.zip
	@cd bin && unzip vault.zip
	@rm bin/vault.zip

# For now we only support Linux 64 bit and MacOS
ifeq ($(shell uname), Darwin)
WANDER_URL_SUFFIX := Darwin_all
else
WANDER_URL_SUFFIX := Linux_x86_64
endif

# Local Wander
bin/wander:
	@mkdir -p bin
	curl -L \
		https://github.com/robinovitch61/wander/releases/download/v$(WANDER_VERSION)/wander_$(WANDER_VERSION)_$(WANDER_URL_SUFFIX).tar.gz | \
		tar -xzf - -C bin wander

# Nomad for the Linux VMs
ansible/roles/nomad/files/nomad:
	curl -o ansible/roles/nomad/files/nomad.zip https://releases.hashicorp.com/nomad/$(NOMAD_VERSION)/nomad_$(NOMAD_VERSION)_linux_amd64.zip
	cd ansible/roles/nomad/files && unzip nomad.zip && rm nomad.zip

# Consul for the Linux VMs
ansible/roles/consul/files/consul:
	curl -o ansible/roles/consul/files/consul.zip https://releases.hashicorp.com/consul/$(CONSUL_VERSION)/consul_$(CONSUL_VERSION)_linux_amd64.zip
	cd ansible/roles/consul/files && unzip consul.zip && rm consul.zip

# Vault for the Linux VMs
ansible/roles/vault/files/vault:
	curl -o ansible/roles/vault/files/vault.zip https://releases.hashicorp.com/vault/$(VAULT_VERSION)/vault_$(VAULT_VERSION)_linux_amd64.zip
	cd ansible/roles/vault/files && unzip vault.zip && rm vault.zip

# Generate an encryption key on the fly
ansible/roles/consul/vars/main.yaml: bin/consul
	@echo "---\nconsul_encryption_key: $(shell ./bin/consul keygen)" > ansible/roles/consul/vars/main.yaml

.PHONY: clean-consul-certs
clean-consul-certs:
	@rm -rf ansible/roles/consul/files/certs

.PHONY: consul-certs
consul-certs: \
	ansible/roles/consul/files/certs/$(DC)-server-consul-$(CONSUL_CERT_SERVER_LAST_INDEX).pem \

# Generate a CA on the fly
ansible/roles/consul/files/certs/consul-agent-ca.pem: bin/consul
	@echo "Generating Consul certificate authority..."
	@# In case an old key is still around, clean it up
	@rm -f ansible/roles/consul/files/consul-agent-ca-key.pem
	@mkdir -p ansible/roles/consul/files/certs
	./bin/consul tls ca create
	mv consul-agent-ca* ansible/roles/consul/files/certs/

ansible/roles/consul/files/certs/consul-agent-ca-key.pem: ansible/roles/consul/files/certs/consul-agent-ca.pem

ansible/roles/consul/files/certs/$(DC)-server-consul-$(CONSUL_CERT_SERVER_LAST_INDEX).pem: ansible/roles/consul/files/certs/consul-agent-ca.pem
	@echo "Generating Consul server certs up to x-$(CONSUL_CERT_SERVER_LAST_INDEX)..."
	@cd ansible/roles/consul/files/certs && \
		for i in $(shell seq 0 $(CONSUL_CERT_SERVER_LAST_INDEX)); do \
			../../../../../bin/consul tls cert create -server -dc $(DC) > /dev/null; \
		done

node_modules: package.json package-lock.json
	npm install
	@touch node_modules

# Make sure "python" points to 3.9.5 version to make sure pyenv is in effect
# and that we have the latest Python for the latest Ansible version to use
.PHONY: ensure-python
ensure-python:
	@test $(shell python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))') = "3.9.5" || \
		(echo "ERROR: Python version must be 3.9.5, please use pyenv to manage the version properly" && exit 1)

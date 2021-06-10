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

.PHONY: ansible-ping
ansible-ping: .venv/bin/ansible
	@cd ansible && ../.venv/bin/ansible -m ping -i inventory all

# Clean any auto-generated things
.PHONY: clean
clean:
	rm -rf .venv

# Local pip
.venv/bin/pip:
	python -m venv .venv

# Local ansible
.venv/bin/ansible: .venv/bin/pip
	./.venv/bin/pip install ansible


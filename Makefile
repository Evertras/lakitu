.PHONY: ensure-env
ensure-env: ensure-python
	@echo Ready to go!

.PHONY: ensure-python
ensure-python:
	@test $(shell python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))') == "3.9" || \
		(echo "ERROR: Python version must be 3.9" && exit 1)


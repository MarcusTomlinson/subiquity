#
# Makefile for subiquity
#
NAME=subiquity
PYTHONSRC=$(NAME)
PYTHONPATH=$(shell pwd):$(shell pwd)/probert
PROBERTDIR=./probert
PROBERT_REPO=https://github.com/canonical/probert
DRYRUN?=--dry-run --bootloader uefi --machine-config examples/simple.json
export PYTHONPATH
CWD := $(shell pwd)

CHECK_DIRS := console_conf/ subiquity/ subiquitycore/
PYTHON := python3

ifneq (,$(MACHINE))
	MACHARGS=--machine=$(MACHINE)
endif

.PHONY: run clean check

all: dryrun

install_deps:
	sudo apt-get install -y python3-urwid python3-pyudev python3-nose python3-flake8 \
		python3-yaml python3-coverage python3-dev pkg-config libnl-genl-3-dev \
		libnl-route-3-dev python3-attr python3-distutils-extra python3-requests \
		python3-requests-unixsocket python3-jsonschema python3-curtin python3-apport \
		python3-bson xorriso isolinux python3-aiohttp probert cloud-init ssh-import-id

i18n:
	$(PYTHON) setup.py build_i18n
	cd po; intltool-update -r -g subiquity

dryrun ui-view: probert i18n
	$(PYTHON) -m subiquity $(DRYRUN) $(MACHARGS)

dryrun-console-conf ui-view-console-conf:
	$(PYTHON) -m console_conf.cmd.tui --dry-run $(MACHARGS)

dryrun-serial ui-view-serial:
	(TERM=att4424 $(PYTHON) -m subiquity $(DRYRUN) --serial)

dryrun-server:
	$(PYTHON) -m subiquity.cmd.server $(DRYRUN)

lint: flake8

flake8:
	@echo 'tox -e flake8' is preferred to 'make flake8'
	$(PYTHON) -m flake8 $(CHECK_DIRS) --exclude gettext38.py,contextlib38.py

unit:
	python3 -m unittest discover

integration:
	echo "Running integration tests..."
	./scripts/runtests.sh

check: unit integration

probert:
	@if [ ! -d "$(PROBERTDIR)" ]; then \
		git clone -q $(PROBERT_REPO) $(PROBERTDIR); \
		(cd probert && $(PYTHON) setup.py build_ext -i); \
	fi

schema: probert
	@$(PYTHON) -m subiquity.cmd.schema > autoinstall-schema.json

clean:
	./debian/rules clean

.PHONY: flake8 lint

export VAGRANT_BOX_UPDATE_CHECK_DISABLE=1
export VAGRANT_CHECKPOINT_DISABLE=1

NOPARALLEL=--no-parallel
DEBUG=--debug

.PHONY: all setup patroni vipmanager clean validate

all: patroni

setup:
	vagrant up $(DEBUG) $(NOPARALLEL) --provision

patroni: setup
	vagrant up $(DEBUG) $(NOPARALLEL) --provision-with=patroni-start

vipmanager: patroni
	vagrant up $(DEBUG) $(NOPARALLEL) --provision-with=vipmanager-setup
	vagrant up $(DEBUG) $(NOPARALLEL) --provision-with=vipmanager-start

clean:
	vagrant destroy -f

validate:
	@vagrant validate
	@if which shellcheck >/dev/null                                          ;\
	then shellcheck provision/*                                              ;\
	else echo "WARNING: shellcheck is not in PATH, not checking bash syntax" ;\
	fi


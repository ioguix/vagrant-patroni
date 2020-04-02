export VAGRANT_BOX_UPDATE_CHECK_DISABLE=1
export VAGRANT_CHECKPOINT_DISABLE=1

.PHONY: all setup patroni vipmanager clean validate

all: patroni

setup:
	vagrant up --provision

patroni: setup
	vagrant up --provision-with=patroni-start

vipmanager: patroni
	vagrant up --provision-with=vipmanager-setup
	vagrant up --provision-with=vipmanager-start

clean:
	vagrant destroy -f

validate:
	@vagrant validate
	@if which shellcheck >/dev/null                                          ;\
	then shellcheck provision/*                                              ;\
	else echo "WARNING: shellcheck is not in PATH, not checking bash syntax" ;\
	fi


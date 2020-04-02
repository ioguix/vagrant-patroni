#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

declare -a ETCD

while getopts "n:e:i:" option; do
    case "${option}" in
        n) NODENAME="${OPTARG}" ;;
	i) VIP_ADDR="${OPTARG}" ;;
        e) ETCD[${#ETCD[@]}]=$OPTARG ;;
    esac
done


echo "Installing packages"
yum install --nogpgcheck --quiet -y -e 0 epel-release
yum install --nogpgcheck --quiet -y -e 0 jq wget
VIP_RPM=$(wget -qO- 'https://api.github.com/repos/cybertec-postgresql/vip-manager/releases/latest'| \
          jq -r '.assets | .[] | select(.content_type == "application/x-rpm") | .browser_download_url')
yum install --nogpgcheck --quiet -y -e 0 "$VIP_RPM"


YAML="/etc/default/vip-manager.yml"
echo "Adding configuration in "$YAML
ETCD_HOSTS=""
for E in "${ETCD[@]}"; do
    IP="${E##*=}"
    ETCD_HOSTS="${ETCD_HOSTS},http://${IP}:2379"
done

cat <<EOF >"$YAML"
interval: 1000
key: "/service/patroni-demo/leader"
nodename: ${NODENAME}

ip: ${VIP_ADDR}
mask: 24
iface: eth1

hosting_type: basic

endpoint_type: etcd
endpoints: [ ${ETCD_HOSTS:1} ]

etcd_user: ""
etcd_password: ""

retry_num: 2
retry_after: 250
EOF


echo "Setting up environnement"
chown postgres: $YAML

#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

NODENAME="$1"
shift
NODES=( "$@" )

ETCD_INITIAL_CLUSTER=""

# hostname and /etc/hosts setup
hostnamectl set-hostname "${NODENAME}"

for N in "${NODES[@]}"; do
    NG=$(sed -n "/${N%=*}\$/p" /etc/hosts|wc -l)
    IP="${N##*=}"
    HOST="${N%=*}"

    if [ "$NG" -eq 0 ]; then
        echo "${N##*=} ${N%=*}" >> /etc/hosts
    fi

    if [ "$HOST" == "$NODENAME" ]; then
        LOCAL_IP="$IP"
    fi

    ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER},${HOST}=http://${IP}:2380"
done

# install required packages
PACKAGES=(
    screen vim bash-completion etcd
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

systemctl --quiet --now enable firewalld

# Firewall settings
firewall-cmd --quiet --permanent --new-service=etcd
firewall-cmd --quiet --permanent --service=etcd --set-short=Etcd
firewall-cmd --quiet --permanent --service=etcd --set-description="Etcd server"
firewall-cmd --quiet --permanent --service=etcd --add-port=2379-2380/tcp
firewall-cmd --quiet --permanent --add-service=etcd
firewall-cmd --quiet --reload

# Etcd setting
mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf-dist
cat <<EOF > /etc/etcd/etcd.conf
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/patroni-clusters.etcd"
ETCD_LISTEN_PEER_URLS="http://${LOCAL_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${LOCAL_IP}:2379,http://127.0.0.1:2379,http://[::1]:2379"
ETCD_NAME="$NODENAME"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${LOCAL_IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${LOCAL_IP}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER:1}"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-clusters"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

systemctl --quiet --now enable etcd

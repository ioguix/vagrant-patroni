# How to bootstrap a Patroni cluster using vagrant

This `Vagrantfile` is bootstrapping a fresh cluster based on CentOS7 with:

* servers `e1`, `e2` and `e3` hosting a etcd cluster
* servers `p1` and `p2` hosting a Patroni/PostgreSQL cluster
* watchdog enabled

Note that NTP is enabled by default (using chrony) in the vagrant box used (`centos/7`).
No need to set it up ourselves.

## Prerequisites:

You need `vagrant` and `vagrant-libvirt`. Everything is tested with versions 2.0.2 and
0.0.40. Please, report your versions if it works with inferior ones.

~~~
apt install make vagrant vagrant-libvirt libvirt-clients # for Debian-like
yum install make vagrant vagrant-libvirt libvirt-client # for RH-like
dnf install make vagrant vagrant-libvirt libvirt-client # for recent RH-like
systemctl enable --now libvirtd
~~~

## Creating the cluster

To create the cluster, run:

~~~
cd vagrant-patroni
make all
~~~

After some minutes and tons of log messages, you can connect to your servers using eg.:

~~~
vagrant ssh p1
~~~

Setup `patronictl`:

~~~
/usr/local/bin/patronictl configure \
  --config-file "${HOME:?}/.config/patroni/patronictl.yaml" \
  --dcs "etcd://10.20.30.55:2379" \
  --namespace "/service"
~~~

Play with the cluster!

~~~
/usr/local/bin/patronictl list patroni-demo
/usr/local/bin/patronictl switchover --help
/usr/local/bin/patronictl switchover patroni-demo --master p2 --candidate p1 --force
~~~

NOTE: We are using patroni's ability to use `etcd` api v3. Depending on your
`etcd` version, you might need to use the following to see `patroni`'s keys
with `etcdctl`.

~~~
export ETCDCTL_API=3
~~~

## Destroying the cluster

To destroy your cluster, run:

~~~
vagrant destroy -f
~~~

## Adding vip-manager to the mix

vip-manager is designed to manage a VIP for your PostgreSQL cluster, it will
automatically start it on the node where PostgreSQL is the leader.

Follow the "Creating the cluster" procedure but use the following command
instead of `make all`:

~~~
make vipmanager
~~~

With the default configuration, the VIP will be `10.20.30.50`.

## Tips

Find all existing VM created by vagrant on your system:

~~~
vagrant global-status
~~~

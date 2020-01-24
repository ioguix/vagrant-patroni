require 'ipaddr'
#require 'yaml'

ENV["LC_ALL"] = 'en_US.utf8'

pgver         = 11
start_ip      = '10.20.30.50'
etcd_nodes    = 'e1', 'e2', 'e3' # you must have 3+ etcd nodes
patroni_nodes = 'p1', 'p2'       # you must have 2+ patroni nodes

Vagrant.configure(2) do |config|

    next_ip    = IPAddr.new(start_ip).succ
    host_ip    = (IPAddr.new(start_ip) & "255.255.255.0").succ.to_s
    nodes_ips  = {}

    ( patroni_nodes + etcd_nodes ).each do |node|
        nodes_ips[node] = next_ip.to_s
        next_ip = next_ip.succ
    end

    # don't mind about insecure ssh key
    config.ssh.insert_key = false

    # https://vagrantcloud.com/search.
    config.vm.box = 'centos/7'

    # hardware and host settings
    config.vm.provider 'libvirt' do |lv|
        lv.cpus = 1
        lv.memory = 512
        lv.watchdog model: 'i6300esb'
        lv.default_prefix = 'patroni_'
    end

    # disable default share
    config.vm.synced_folder ".", "/vagrant", disabled: true

    ## allow root@vm to ssh to ssh_login@network_1
    #config.vm.synced_folder 'ssh', '/root/.ssh', type: 'rsync',
    #    owner: 'root', group: 'root',
    #    rsync__args: [ "--verbose", "--archive", "--delete", "--copy-links", "--no-perms" ]

    # system setup for etcd ndoes
    (etcd_nodes).each do |node|
        config.vm.define node do |conf|
            conf.vm.network 'private_network', ip: nodes_ips[node]
            conf.vm.provision 'etcd-setup', type: 'shell', path: 'provision/etcd.bash',
                args: [ node ] + etcd_nodes.map {|n| "#{n}=#{nodes_ips[n]}"},
                preserve_order: true
        end
    end

    # system setup for patroni ndoes
    (patroni_nodes).each do |node|
        config.vm.define node do |conf|
            args = [ '-n', node, '-v', pgver ];
            (patroni_nodes).each do |p|
                args.push("-p", "#{p}=#{nodes_ips[p]}")
            end
            (etcd_nodes).each do |e|
                args.push("-e", "#{e}=#{nodes_ips[e]}")
            end
            
            conf.vm.network 'private_network', ip: nodes_ips[node]
            conf.vm.provision 'patroni-setup', type: 'shell', path: 'provision/patroni.bash',
                args: args,
                preserve_order: true
        end
    end

    # Start Patroni on all nodes
    (patroni_nodes).each do |node|
        config.vm.define node do |conf|
            conf.vm.provision 'patroni', type: 'shell',
                inline: 'systemctl start patroni@demo', run: 'never'
        end
    end
end

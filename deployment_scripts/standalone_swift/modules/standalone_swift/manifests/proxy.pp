# standalone_swift class

class standalone_swift::proxy {


include ceilometer
include memcached

    notice('Fuel plugin swift, standalone_swift puppet module, proxy.pp')

    $swift_hash            = hiera('swift_hash')
    $swift_nodes           = filter_nodes(hiera('nodes_hash'),'role','swift-storage')
    $swift_nodes_fix_zone  = fix_zone($swift_nodes)
    $proxy_port            = pick($swift_hash['proxy_port'], '8080')
    $network_scheme        = hiera('network_scheme', {})
    $storage_hash          = hiera('storage_hash')
    $mp_hash               = hiera('mp')
    $management_vip        = hiera('management_vip')
    $debug                 = hiera('debug', false)
    $verbose               = hiera('verbose')
    $storage_address       = hiera('storage_address')
    $node                  = hiera('node')
    $ring_min_part_hours   = hiera('swift_ring_min_part_hours', 1)
    $swift_partition       = pick($swift_hash['swift_partition'], '/var/lib/storage')
    $loopback_size         = pick($swift_hash['loopback_size'], '5243780')
    $storage_type          = pick($swift_hash['storage_type'], false)
    $nodes_hash            = hiera('nodes')
    $proxies               = concat(filter_nodes($nodes_hash,'role', 'primary-swift-proxy'), filter_nodes($nodes_hash,'role', 'swift-proxy'))
    $swift_proxies         = nodes_to_hash($proxies,'name','internal_address')
    $primary_swift         = filter_nodes(hiera('nodes_hash'),'role','primary-swift-proxy')
    $master_swift_proxy_ip = $primary_swift[0]['storage_address']

    $ring_part_power = pick($swift_hash['partition_power'], 15)
    $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
    $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

    # Configure networking on a node, during a stage prior to main
    prepare_network_config(hiera('network_scheme'))
    $stub = generate_network_config()

    stage {'netconfig':
      before  => Stage['main'],
    }
    class { 'l23network' :
      use_ovs => true,
      stage   => 'netconfig',
    }

    $node_role = hiera('role')
    $primary_proxy            = $node_role ? { 'primary-swift-proxy' => true, default =>false } 

    # Generate rings on a primary controller node
    if $primary_proxy {
      ring_devices {'all':
        storages => $swift_nodes_fix_zone,
        require  => Class['swift'],
      }
    }

    class { 'openstack::swift::proxy':
        swift_user_password     => $swift_hash['user_password'],
        swift_proxies           => $swift_proxies,
        ring_part_power         => $ring_part_power,
        primary_proxy           => $primary_proxy,
        controller_node_address => $management_vip,
        swift_local_net_ip      => $storage_address,
        master_swift_proxy_ip   => $master_swift_proxy_ip,
        proxy_port              => $proxy_port,
        debug                   => $debug,
        verbose                 => $verbose,
        log_facility            => 'LOG_SYSLOG',
        ceilometer              => hiera('use_ceilometer',false),
        ring_min_part_hours     => $ring_min_part_hours,
    } ->

    package { 'fuel-ha-utils':
      ensure => installed,
    } ->

    class { 'openstack::swift::status':
      endpoint    => "http://${storage_address}:${proxy_port}",
      vip         => $management_vip,
      only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
      con_timeout => 5
    }

    # setup a cronjob to rebalance and repush rings periodically
    class { 'openstack::swift::rebalance_cronjob':
      ring_rebalance_period => min($ring_min_part_hours * 2, 23),
      master_swift_proxy_ip => $master_swift_proxy_ip,
      primary_proxy         => $primary_proxy,
    }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
class standalone_swift::storage {

  notice('MODULAR: standalone_swift/storage.pp')

  include ceilometer
  include memcached

    notice('Fuel plugin swift, standalone_swift puppet module, storage.pp')

    $swift_hash            = hiera('swift_hash')
    $network_metadata      = hiera('network_metadata', {})
    $swift_nodes           = get_nodes_hash_by_roles($network_metadata, ['primary-swift-proxy', 'swift-proxy'])
echo($swift_nodes, 'swift_nodes')
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
    $loopback_size         = pick($swift_hash['loopback_size'], '5243780')
    $storage_type          = pick($swift_hash['storage_type'], false)
    $swift_zone            = hiera('swift_zone', 1)

    # Check swift::storage::all manifest for details on custom device paths
    $swift_account_device   = pick($swift_hash['swift_account_device'], '/srv/node')
    $swift_container_device = pick($swift_hash['swift_container_device'], '/srv/node')
    $swift_object_device    = pick($swift_hash['swift_object_device'], '/var/lib/glance/node')

    $swift_device_list = unique([ $swift_account_device, $swift_container_device, $swift_object_device ])

    # Test if storage node name has zone assignment
#    validate_re($node[0]['user_node_name'], '^.*zone-[1-9]\d*$', 'Storage node does not have zone assignment in the user defined node name')
    # Fetch zone number from user_node_name
 #   $swift_zone = inline_template("<%= $node['user_node_name'][/^.*zone-([1-9]\d*)$/, 1] %>")

    $nodes_hash            = hiera('nodes')
    $proxies               = concat(filter_nodes($nodes_hash,'role', 'primary-swift-proxy'), filter_nodes($nodes_hash,'role', 'swift-proxy'))
    $swift_proxies         = nodes_to_hash($proxies,'name','internal_address')
    $primary_swift         = filter_nodes(hiera('nodes_hash'),'role','primary-swift-proxy')

    $swift_master_role             = 'primary-swift-proxy'
    $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
    $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
    $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')

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

    file { $swift_device_list:
      ensure => 'directory',
      owner  => 'swift',
      group  => 'swift',
      mode   => '0750',
    } ->
    class { 'openstack::swift::storage_node':
        storage_type          => $storage_type,
        loopback_size         => $loopback_size,
        storage_mnt_base_dir  => $swift_object_device,
        storage_devices       => filter_hash($mp_hash,'point'),
        swift_zone            => $master_swift_proxy_nodes_list[0]['swift_zone'],
        sync_rings            => ! $primary_proxy,
        debug                 => $debug,
        verbose               => $verbose,
        log_facility          => 'LOG_SYSLOG',
        master_swift_replication_ip  => $master_swift_replication_ip,
        master_swift_proxy_ip => $master_swift_proxy_ip,
    }

  # setup a cronjob to rebalance and repush rings periodically

  class { 'openstack::swift::rebalance_cronjob':
    ring_rebalance_period => min($ring_min_part_hours * 2, 23),
    primary_proxy         => $primary_proxy,
    master_swift_replication_ip => $master_swift_replication_ip,
  }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}

# Class[Swift::Proxy::Cache] requires Class[Memcached] if memcache_servers
# contains 127.0.0.1. But we're deploying memcached in another task. So we
# need to add this stub here.
class memcached {}

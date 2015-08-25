# standalone_swift class

class standalone_swift::storage {


include ceilometer
include memcached


    notice('Fuel plugin swift, standalone_swift puppet module, init.pp')

    $network_metadata      = hiera('network_metadata')
    $swift_hash            = hiera('swift_hash')
 #   $swift_nodes           = filter_nodes(hiera('nodes_hash'),'role','swift-storage')
    $swift_nodes           = get_nodes_hash_by_roles($network_metadata, ['swift-storage'])
    $primary_swift         = filter_nodes(hiera('nodes_hash'),'role','primary-swift-proxy')
    #$master_swift_proxy_ip = $primary_swift[0]['storage_address']
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
    $resize_value          = pick($swift_hash['resize_value'], 2)

#Keystone settings
$service_endpoint        = hiera('service_endpoint')
$keystone_user           = pick($swift_hash['user'], 'swift')
$keystone_password       = pick($swift_hash['user_password'], 'passsword')
$keystone_tenant         = pick($swift_hash['tenant'], 'services')
$keystone_protocol       = pick($swift_hash['auth_protocol'], 'http')
$region                  = hiera('region', 'RegionOne')

    $proxies             = filter_nodes_nonstrict(hiera('nodes_hash'),'user_node_name','^swift-proxy-(primary-)?\d*$')
    $swift_proxies       = nodes_to_hash($proxies,'name','internal_address')

    $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
    $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
    $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

  $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, ['primary-swift-proxy'])
  $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
  $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
  $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')

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
    
      file { $swift_partition:
        ensure => 'directory',
        owner  => 'swift',
        group  => 'swift',
        mode   => '0750',
      } ->

      class { 'openstack::swift::storage_node':
        storage_type          => $storage_type,
        loopback_size         => $loopback_size,
        storage_mnt_base_dir  => $swift_partition,
        storage_devices       => filter_hash($mp_hash,'point'),
        swift_zone            => $node['swift_zone'],
        swift_local_net_ip    => $storage_address,
        master_swift_proxy_ip => $master_swift_proxy_ip,
        master_swift_replication_ip => $master_swift_replication_ip,
        sync_rings            => ! $primary_proxy,
        debug                 => $debug,
        verbose               => $verbose,
        log_facility          => 'LOG_SYSLOG',
      }


    # setup a cronjob to rebalance and repush rings periodically
    class { 'openstack::swift::rebalance_cronjob':
      ring_rebalance_period => min($ring_min_part_hours * 2, 23),
      master_swift_replication_ip => $master_swift_replication_ip,
      primary_proxy         => $primary_proxy,
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

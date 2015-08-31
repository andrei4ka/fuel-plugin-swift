# standalone_swift class

class standalone_swift::proxy {


include ceilometer
include memcached

    notice('Fuel plugin swift, standalone_swift puppet module, proxy.pp')

    $network_metadata      = hiera('network_metadata')
    $swift_hash            = hiera('swift_hash')
    $swift_nodes           = get_nodes_hash_by_roles($network_metadata, ['swift-storage'])
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

    #Keystone settings
    $service_endpoint        = hiera('service_endpoint')
    $keystone_user           = pick($swift_hash['user'], 'swift')
    $keystone_password       = pick($swift_hash['user_password'], 'passsword')
    $keystone_tenant         = pick($swift_hash['tenant'], 'services')
    $keystone_protocol       = pick($swift_hash['auth_protocol'], 'http')
    $region                  = hiera('region', 'RegionOne')

    $proxies             = filter_nodes_nonstrict(hiera('nodes_hash'),'user_node_name','^swift-proxy-(primary-)?\d*$')
    $swift_proxies       = nodes_to_hash($proxies,'name','internal_address')

    $ring_part_power = pick($swift_hash['partition_power'], 15)
    $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
    $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

    $swift_api_ipaddr        = regsubst($node['network_roles']['swift/api'], '\/\d+$', '')
    $swift_storage_ipaddr    = regsubst($node['network_roles']['swift/replication'], '\/\d+$', '')

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

    # Generate rings on a primary controller node
    if $primary_proxy {
      ring_devices {'all':
        storages => $swift_nodes_fix_zone,
        require  => Class['swift'],
      }
    }

    class { 'openstack::swift::proxy':
    swift_user_password            => $swift_hash['user_password'],
    swift_proxies_cache            => $memcaches_addr_list,
    ring_part_power                => $ring_part_power,
    primary_proxy                  => $primary_proxy,
    swift_proxy_local_ipaddr       => $swift_api_ipaddr,
    swift_replication_local_ipaddr => $swift_storage_ipaddr,
    master_swift_proxy_ip          => $master_swift_proxy_ip,
    master_swift_replication_ip    => $master_swift_replication_ip,
    proxy_port                     => $proxy_port,
    debug                          => $debug,
    verbose                        => $verbose,
    log_facility                   => 'LOG_SYSLOG',
    ceilometer                     => hiera('use_ceilometer',false),
    ring_min_part_hours            => $ring_min_part_hours,
    admin_user                     => $keystone_user,
    admin_tenant_name              => $keystone_tenant,
    admin_password                 => $keystone_password,
    auth_host                      => $service_endpoint,
    auth_protocol                  => $keystone_protocol,
    } ->

    package { 'fuel-ha-utils':
      ensure => installed,
    } ->

    class { 'openstack::swift::status':
      endpoint    => "http://${swift_api_ipaddr}:${proxy_port}",
      vip         => $management_vip,
      only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
      con_timeout => 5
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

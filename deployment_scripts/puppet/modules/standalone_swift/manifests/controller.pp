# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

#  $use_neutron                    = hiera('use_neutron', false)
#  $ceilometer_hash                = hiera_hash('ceilometer',{})
#  $sahara_hash                    = hiera_hash('sahara', {})
#  $murano_hash                    = hiera_hash('murano', {})
#  $storage_hash                   = hiera_hash('storage', {})
#  $controllers                    = hiera('controllers')
#  $haproxy_nodes                  = hiera('haproxy_nodes', $controllers)
#  $rgw_servers                    = undef
#
#  $swift_proxies = filter_nodes_nonstrict(hiera('nodes_hash'),'user_node_name','^swift-proxy-(primary-)?\d*$')
#
#  class { '::openstack::ha::haproxy':
#    controllers              => $haproxy_nodes,
#    public_virtual_ip        => hiera('public_vip'),
#    internal_virtual_ip      => hiera('management_vip'),
#    horizon_use_ssl          => hiera('horizon_use_ssl', false),
#    neutron                  => $use_neutron,
#    queue_provider           => 'rabbitmq',
#    custom_mysql_setup_class => hiera('custom_mysql_setup_class','galera'),
#    swift_proxies            => $swift_proxies,
#   rgw_servers              => $rgw_servers,
#    ceilometer               => $ceilometer_hash['enabled'],
#    sahara                   => $sahara_hash['enabled'],
#    murano                   => $murano_hash['enabled'],
#    is_primary_controller    => hiera('primary_controller'),
#  }


$network_metadata = hiera_hash('network_metadata')
$storage_hash     = hiera_hash('storage', {})
$swift_proxies    = get_nodes_hash_by_roles($network_metadata, ['primary-swift-proxy', 'swift-proxy'])
$public_ssl_hash  = hiera('public_ssl')


$swift_proxies_address_map = get_node_to_ipaddr_map_by_network_role($swift_proxies, 'swift/api')


  $server_names        = hiera_array('swift_server_names', keys($swift_proxies_address_map))
  $ipaddresses         = hiera_array('swift_ipaddresses', values($swift_proxies_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure swift ha proxy
  class { '::openstack::ha::swift':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }

  service { 'swift-account':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-account-auditor':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-account-reaper':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-account-replicator':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-container':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-container-auditor':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-container-replicator':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-container-sync':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-object':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-object-auditor':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-container-updater':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-object-replicator':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-object-updater':
    ensure => 'stopped',
    enable => false,
  }
  service { 'swift-proxy':
    ensure => 'stopped',
    enable => false,
  }

}

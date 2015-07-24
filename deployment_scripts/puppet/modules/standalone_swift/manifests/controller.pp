# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

  $use_neutron                    = hiera('use_neutron', false)
  $ceilometer_hash                = hiera_hash('ceilometer',{})
  $sahara_hash                    = hiera_hash('sahara', {})
  $murano_hash                    = hiera_hash('murano', {})
  $storage_hash                   = hiera_hash('storage', {})
  $controllers                    = hiera('controllers')
  $haproxy_nodes                  = hiera('haproxy_nodes', $controllers)
  $rgw_servers                    = undef

  $swift_proxies = filter_nodes_nonstrict(hiera('nodes_hash'),'user_node_name','^swift-proxy-(primary-)?\d*$')

  class { '::openstack::ha::haproxy':
    controllers              => $haproxy_nodes,
    public_virtual_ip        => hiera('public_vip'),
    internal_virtual_ip      => hiera('management_vip'),
    horizon_use_ssl          => hiera('horizon_use_ssl', false),
    neutron                  => $use_neutron,
    queue_provider           => 'rabbitmq',
    custom_mysql_setup_class => hiera('custom_mysql_setup_class','galera'),
    swift_proxies            => $swift_proxies,
    rgw_servers              => $rgw_servers,
    ceilometer               => $ceilometer_hash['enabled'],
    sahara                   => $sahara_hash['enabled'],
    murano                   => $murano_hash['enabled'],
    is_primary_controller    => hiera('primary_controller'),
  }

}

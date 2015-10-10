# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

  $internal_virtual_ip = hiera('management_vip')
  $public_virtual_ip   = hiera('public_vip')
  $network_metadata    = hiera('network_metadata')
  $controllers_hash    = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
  $swift_proxies_hash    = get_nodes_hash_by_roles($network_metadata, ['primary-swift-proxy', 'swift-proxy'])
  $public_ssl_hash     = hiera('public_ssl')
#  $controllers         = hiera('controllers')
  $nodes_hash          = hiera('nodes')
  $swift_proxies       = concat(filter_nodes($nodes_hash,'role', 'primary-swift-proxy'), filter_nodes($nodes_hash,'role', 'swift-proxy'))
  $swift_storages      = filter_nodes($nodes_hash,'role', 'swift-storage')

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($controllers_hash, 'name'),
    ipaddresses         => filter_hash($controllers_hash, 'internal_address'),
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }


  class { '::openstack::ha::swift':
    server_names        => $swift_storages,
    ipaddresses         => filter_hash($swift_proxies_hash, 'internal_address'),
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
    public_ssl          => $public_ssl_hash['services'],
  }

  $services = ['swift-account', 'swift-account-auditor', 'swift-account-reaper', 'swift-account-replicator', 'swift-container', 'swift-container-auditor', 'swift-container-replicator',
              'swift-container-sync', 'swift-object', 'swift-object-auditor', 'swift-container-updater', 'swift-object-replicator', 'swift-object-updater', 'swift-proxy']

  $packages = ['swift-proxy', 'swift-container', 'swift-object']

  package { $packages:
    ensure => absent,
  }
  service { $services:
    ensure => stopped,
    enable => false,
  }

  Package <||> ~> Service <||>

}

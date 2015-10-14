# Standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

  notice('MODULAR: standalone_swift/controller.pp')

  # Getting and transforming data from hiera
  $internal_virtual_ip = hiera('management_vip')
  $public_virtual_ip   = hiera('public_vip')
  $network_metadata    = hiera('network_metadata')
  $controllers_hash    = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
  $public_ssl_hash     = hiera('public_ssl')
  $nodes_hash          = hiera('nodes')
  $swift_proxies       = concat(filter_nodes($nodes_hash,'role', 'primary-swift-proxy'), filter_nodes($nodes_hash,'role', 'swift-proxy'))
  $ipaddresses         = filter_hash($swift_proxies, 'internal_address')
  $server_names        = filter_hash($swift_proxies, 'name')

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => $server_names,
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => filter_hash($controllers_hash, 'internal_address'),
  }

  class { '::openstack::ha::swift':
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
    server_names        => $server_names,
    ipaddresses         => $ipaddresses,
    public_ssl          => $public_ssl_hash['services'],
  }

  # Service-list to stop on Controllers
  $services = ['swift-account', 'swift-account-auditor', 'swift-account-reaper', 'swift-account-replicator', 'swift-container', 'swift-container-auditor', 'swift-container-replicator',
              'swift-container-sync', 'swift-object', 'swift-object-auditor', 'swift-container-updater', 'swift-object-replicator', 'swift-object-updater', 'swift-proxy']

  # Packages to remove from Controllers
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

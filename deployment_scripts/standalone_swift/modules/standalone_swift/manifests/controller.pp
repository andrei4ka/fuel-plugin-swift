# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

  $internal_virtual_ip = hiera('management_vip')
  $public_virtual_ip   = hiera('public_vip')
  $controllers         = hiera('controllers')
  $nodes_hash          = hiera('nodes')
  $swift_proxies       = concat(filter_nodes($nodes_hash,'role', 'primary-swift-proxy'), filter_nodes($nodes_hash,'role', 'swift-proxy'))

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($controllers, 'name'),
    ipaddresses         => filter_hash($controllers, 'internal_address'),
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }

  class { '::openstack::ha::swift':
    servers => $swift_proxies,
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

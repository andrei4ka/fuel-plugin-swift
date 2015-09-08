# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

  $internal_virtual_ip = hiera('management_vip')
  $public_virtual_ip   = hiera('public_vip')
  $controllers         = hiera('controllers')
  $swift_proxies       = filter_nodes_nonstrict(hiera('nodes_hash'),'role','^(primary-)?swift-proxy$')

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

  service { 'swift-account':
    ensure => 'stopped',
  }
  service { 'swift-account-auditor':
    ensure => 'stopped',
  }
  service { 'swift-account-reaper':
    ensure => 'stopped',
  }
  service { 'swift-account-replicator':
    ensure => 'stopped',
  }
  service { 'swift-container':
    ensure => 'stopped',
  }
  service { 'swift-container-auditor':
    ensure => 'stopped',
  }
  service { 'swift-container-replicator':
    ensure => 'stopped',
  }
  service { 'swift-container-sync':
    ensure => 'stopped',
  }
  service { 'swift-object':
    ensure => 'stopped',
  }
  service { 'swift-object-auditor':
    ensure => 'stopped',
  }
  service { 'swift-container-updater':
    ensure => 'stopped',
  }
  service { 'swift-object-replicator':
    ensure => 'stopped',
  }
  service { 'swift-object-updater':
    ensure => 'stopped',
  }
  service { 'swift-proxy':
    ensure => 'stopped',
  }

  package { 'swift-proxy':
    ensure => absent,
    require => Service['swift-proxy'],
  }
  package { 'swift-container':
    ensure => absent,
    require => Service['swift-container'],
  }
  package { 'swift-object':
    ensure => absent,
    require => Service['swift-object'],
  }

}

# standalone_swift::controller class configures haproxy on controller nodes
# $swift_proxies contains swift proxy nodes now, not controllers

class standalone_swift::controller {

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

}

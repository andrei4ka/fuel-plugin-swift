module Puppet::Parser::Functions
  newfunction(:fix_zone, :type => :rvalue) do |args|
    hash = args[0]
    hash.each do |key, array|
      if array['user_node_name'][/^.*zone-(\d*)$/, 1]  # If user assigned node name contains 'zone-N' where N is a number
        array['swift_zone'] = array['user_node_name'][/^.*zone-(\d*)$/, 1]   # Substitute swift_zone number with this number
      end
    end
    hash
  end
end

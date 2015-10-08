module Puppet::Parser::Functions
  newfunction(:fix_zone, :type => :rvalue) do |args|
    array = args[0]
    array.each do | item |
      if item['user_node_name'][/^.*zone-([1-9]\d*)$/, 1]  # If user assigned node name contains 'zone-N' where N is a number
        item['swift_zone'] = item['user_node_name'][/^.*zone-([1-9]\d*)$/, 1]   # Substitute swift_zone number with this number
      end
    end
    array
  end
end

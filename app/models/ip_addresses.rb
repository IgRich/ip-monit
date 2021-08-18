class IpAddress < Sequel::Model(DbConnection.connect[:ip_addresses])
end
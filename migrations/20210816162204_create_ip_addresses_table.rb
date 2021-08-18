Sequel.migration do
  up do
    create_table(:ip_addresses) do
      primary_key :id
      inet :address, null: false

      index :address, unique: true
    end
  end

  down do
    drop_table(:ip_addresses)
  end
end

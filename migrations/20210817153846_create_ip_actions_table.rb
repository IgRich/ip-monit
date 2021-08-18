Sequel.migration do
  up do
    create_table(:ip_actions) do
      primary_key :id
      inet :address, null: false
      Integer :state, null: false
      Integer :action, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:state, :created_at]
    end
  end

  down do
    drop_table(:ip_actions)
  end
end

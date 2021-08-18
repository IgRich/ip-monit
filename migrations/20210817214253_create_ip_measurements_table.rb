Sequel.migration do
  up do
    create_table(:ip_measurements) do
      primary_key :id
      inet :address, null: false
      DateTime :performed_at, null: false
      Float :min_rtt, null: false
      Float :max_rtt, null: false
      Float :avg_rtt, null: false
      Float :lost_package_percent, null: false

      index [:address, :performed_at]
    end
  end

  down do
    drop_table(:ip_measurements)
  end
end

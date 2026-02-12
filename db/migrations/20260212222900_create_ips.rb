Sequel.migration do
  change do
    create_table(:ips) do
      primary_key :id
      column :address, 'inet', null: false, unique: true
      TrueClass :enabled, default: true, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end

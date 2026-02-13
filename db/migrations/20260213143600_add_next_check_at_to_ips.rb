Sequel.migration do
  change do
    alter_table(:ips) do
      add_column :next_check_at, 'timestamptz'
      add_index :next_check_at, where: Sequel.lit('enabled = true'), name: :idx_ips_next_check_enabled
    end
  end
end

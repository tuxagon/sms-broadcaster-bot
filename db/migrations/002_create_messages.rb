Sequel.migration do
  change do
    create_table(:messages) do
      primary_key :id
      column :message_id, :string
      foreign_key :contact_id, :contacts, on_delete: :cascade
    end
  end
end

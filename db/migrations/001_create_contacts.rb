Sequel.migration do
  change do
    create_table(:contacts) do
      primary_key :id
      column :name, :string
      column :phone, :string
      column :carrier, :string
      column :chat_id, :bignum
      column :created_at, :datetime, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
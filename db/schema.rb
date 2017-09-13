require 'logger'
require 'sequel'

LOGGERS = [
  Logger.new($stdout),
  Logger.new('db/db.log')
].freeze

DB = Sequel.sqlite('db/bot.db', loggers: LOGGERS)

DB.create_table? :chats do
  column :id, :bignum, primary_key: true
  column :created_at, :datetime, default: Sequel::CURRENT_TIMESTAMP
end

DB.create_table? :contacts do
  primary_key :id
  column :name, :string
  column :phone, :string
  column :carrier, :string
  foreign_key :chat_id, :chats, on_delete: :cascade
end
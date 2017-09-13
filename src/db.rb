require 'logger'
require 'sequel'

DATABASE = 'db/bot.db'.freeze
LOGGERS = [
  Logger.new($stdout),
  Logger.new('db/db.log')
].freeze

class BotDB
  def self.contacts(chat_id)
    conn[:contacts]
      .where(chat_id: chat_id)
      .map { |c| c }
  end

  def self.upsert_contact(contact, chat_id)
    dataset = conn[:contacts]
    if contact[:id].nil?
      dataset.insert(
        name: contact[:name], 
        phone: contact[:phone], 
        carrier: contact[:carrier],
        chat_id: chat_id)
    else
      dataset
        .where(id: contact[:id])
        .update(
          name: contact[:name], 
          phone: contact[:phone], 
          carrier: contact[:carrier])
    end
  end

  def self.delete_contact(contact_id, chat_id)
    conn[:contacts]
      .where { (id == contact_id) & (chat_id == chat_id) }
      .delete
  end

  def self.migrate
    conn.create_table? :contacts do
      primary_key :id
      column :name, :string
      column :phone, :string
      column :carrier, :string
      column :chat_id, :bignum
      column :created_at, :datetime, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  def self.conn
    Sequel.sqlite(DATABASE, loggers: LOGGERS)
  end
end
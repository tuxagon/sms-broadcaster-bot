require 'logger'
require 'sequel'
require 'yaml'

class DatabaseConnector
  def connect
    Sequel.connect(connection_details, loggers: loggers)
  end

  def contacts
    connect[:contacts]
  end

  def contacts_by_chat(chat_id)
    contacts.where(chat_id: chat_id).map { |c| c }
  end

  def messages_by_contact(contact_id)
    connect[:messages].where(contact_id: contact_id).map { |m| m }
  end

  def insert_message(contact_id, message_id)
    connect[:messages].insert(contact_id: contact_id, message_id: message_id)
  end

  private 

  def loggers
    [Logger.new('db/debug.log')]
  end

  def connection_details
    YAML.load(File.open('config/database.yml'))
  end
end
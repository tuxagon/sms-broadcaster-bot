require 'logger'
require 'sequel'
require 'yaml'

class DatabaseConnector
  def connect
    Sequel.connect(connection_details, loggers: loggers)
  end

  def contacts_by_chat(chat_id)
    connect[:contacts].where(chat_id: chat_id).map { |c| c }
  end

  private 

  def loggers
    [Logger.new('db/debug.log')]
  end

  def connection_details
    YAML.load(File.open('config/database.yml'))
  end
end
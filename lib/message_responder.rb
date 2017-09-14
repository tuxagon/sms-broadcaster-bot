require 'i18n'

require_relative 'database_connector.rb'
require_relative 'message_sender.rb'
require_relative 'sms_sender.rb'

class MessageResponder
  attr_reader :from_email
  attr_reader :message
  attr_reader :bot
  attr_reader :db

  def initialize(options)
    @bot = options[:bot]
    @from_email = options[:from_email]
    @message = options[:message]
    @db = DatabaseConnector.new
  end

  def respond
    on(/^\/broadcast(.*)/) do |text|
      puts message.chat.id
      send_sms(text.strip) unless text.nil?
    end
  end

  private

  def on(regex, &block)
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      when 2
        yield $1, $2
      end
    end
  end

  def send_sms(text)
    if text.empty?
      bot.api.send_message(
        chat_id: message.chat.id, 
        text: I18n.t('wont_send_blank_message'))
      return
    end

    contacts = @db.contacts_by_chat(message.chat.id)
    if contacts.length.zero?
      bot.api.send_message(
        chat_id: message.chat.id, 
        text: I18n.t('no_contacts_message'))
      return
    end

    options = {
      contacts: contacts, 
      message: message,
      from_email: from_email
    }
    sent_message = SmsSender.new(options).send(text)
    bot.api.send_message(chat_id: message.chat.id, text: sent_message)
  end
end
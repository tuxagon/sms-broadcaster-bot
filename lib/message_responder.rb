require 'i18n'

require_relative 'database_connector'
require_relative 'message_sender'
require_relative 'sms_sender'

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :db

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @db = DatabaseConnector.new
  end

  def respond
    on(/^\/broadcast(.*)/) do |text|
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
      answer_with_message(I18n.t('wont_send_blank_message'))
      return
    end

    contacts = @db.contacts_by_chat(message.chat.id)
    if contacts.length.zero?
      answer_with_message(I18n.t('no_contacts_message'))
      return
    end

    options = {
      contacts: contacts, 
      message: message
    }

    text = "FROM #{message.chat.title}: #{text}"
    answer_with_message(SmsSender.new(options).send(text))
  end

  private 

  def answer_with_message(text)
    MessageSender.new(bot: bot, chat: message.chat, text: text).send
  end
end
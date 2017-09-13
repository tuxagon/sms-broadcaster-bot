require_relative 'config'
require_relative 'db'
require 'mail'
require 'net/smtp'
require 'telegram/bot'
require 'yaml'

COMMANDS = {
  '/broadcast' => :send_sms
}.freeze

class Email
  def initialize(**smtp)
    Mail.defaults do
      delivery_method :smtp, {
        address: smtp[:host], 
        port: smtp[:port],
        user_name: smtp[:username],
        password: smtp[:password],
        authentication: smtp[:authentication]
      }
    end
  end

  def send(email, body)
    mail = Mail.new do
      from    'tuxagon91@gmail.com'
      to      email
      subject 'telegram'
      body    body
    end
    mail.deliver
  end
end

# Represents the SMS Broadcaster telegram bot
class SmsBroadcasterBot
  def initialize(config_file)
    @config = Config.new(config_file)
    @email = Email.new(@config.get(:secrets, :smtp))
  end

  def run
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        COMMANDS.each do |cmd, func|
          if message.text.downcase.start_with?(cmd)
            send(func, bot, strip_command(message, cmd))
          end
        end
      end
    end
  end

  def send_sms(bot, message)
    contacts = BotDB.contacts(message.chat.id)
    if contacts.length.zero?
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'No contacts configured')
      return
    end

    new_message = ''
    contacts.each do |contact|
      email = "#{contact[:phone]}@#{map_carrier(contact[:carrier])}"
      @email.send(email, message.text)
      new_message += "SMS sent to #{contact[:name]} #{email}\n"
    end

    bot.api.send_message(chat_id: message.chat.id, text: new_message)
  end

  def map_carrier(carrier)
    case carrier.to_sym
    when :alltel 
      'message.alltel.com' # mms.alltelwireless.com
    when :att
      'txt.att.net' # mms.att.net
    when :boost
      'myboostmobile.com' # myboostmobile.com
    when :cricket
      'mms.cricketwireless.net'
    when :projectfi
      'msg.fi.google.com'
    when :sprint
      'messaging.sprintpcs.com' # pm.sprint.com
    when :tmobile
      'tmomail.net' # tmomail.net
    when :uscellular
      'email.uscc.net' # mms.uscc.net
    when :verizon
      'vtext.com' # vzwpix.com
    when :virgin
      'vmobl.com' # vmpix.com
    when :republic
      'text.republicwireless.com'
    end
  end

  def strip_command(message, cmd)
    message.text = message.text.sub(cmd, '').strip
    message
  end

  def token
    @config.get(:secrets, :telegram, :token)
  end

  private :strip_command, :token, :map_carrier
end

config_file = ARGV[2] if ARGV.length > 2
SmsBroadcasterBot.new(config_file).run

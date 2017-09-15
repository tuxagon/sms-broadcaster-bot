require 'i18n'
require 'mail'

require_relative 'app_configurator'

CARRIERS = {
  #alltel: 'message.alltel.com',
  alltel: 'mms.alltelwireless.com',
  #att: 'txt.att.net',
  att: 'mms.att.net',
  #boost: 'myboostmobile.com',
  boost: 'myboostmobile.com',
  cricket: 'mms.cricketwireless.net',
  projectfi: 'msg.fi.google.com',
  #sprint: 'messaging.sprintpcs.com',
  sprint: 'pm.sprint.com',
  #tmobile: 'tmomail.net',
  tmobile: 'tmomail.net',
  #uscellular: 'email.uscc.net',
  uscellular: 'mms.uscc.net',
  #verizon: 'vtext.com',
  verizon: 'vzwpix.com',
  #virgin: 'vmobl.com',
  virgin: 'vmpix.com',
  republicwireless: 'text.republicwireless.com'
}.freeze

class SmsSender
  attr_reader :contacts
  attr_reader :from_email
  attr_reader :message
  
  def initialize(options)
    @contacts = options[:contacts]
    @message = options[:message]
    @from_email = AppConfigurator.new.get_from_email
  end

  def send(body)
    sent_message = ''
    contacts.each do |contact|
      to_email = construct_email(contact)
      send_to(to_email, body)
      sent_message += "SMS sent to #{contact[:name]} #{to_email}\n"
    end
    sent_message
  end

  private

  def send_to(to_email, body)
    mail = Mail.new do
      to      to_email
      subject I18n.t('message_subject')
      body    body
    end
    mail[:from] = from_email
    mail.deliver
  end

  def construct_email(contact)
    "#{contact[:phone]}@#{CARRIERS[contact[:carrier].to_sym]}"
  end
end
require 'i18n'
require 'mail'

CARRIERS = {
  alltel: 'message.alltel.com',
  alltelmms: 'mms.alltelwireless.com',
  att: 'txt.att.net',
  attmms: 'mms.att.net',
  boost: 'myboostmobile.com',
  boostmms: 'myboostmobile.com',
  cricket: 'mms.cricketwireless.net',
  projectfi: 'msg.fi.google.com',
  sprint: 'messaging.sprintpcs.com',
  sprintmms: 'pm.sprint.com',
  tmobile: 'tmomail.net',
  tmobilemms: 'tmomail.net',
  uscellular: 'email.uscc.net',
  uscellularmms: 'mms.uscc.net',
  verizon: 'vtext.com',
  verizonmms: 'vzwpix.com',
  virgin: 'vmobl.com',
  virginmms: 'vmpix.com',
  republicwireless: 'text.republicwireless.com'
}.freeze

SMS_BYTE_LIMIT = 140.freeze

class SmsSender
  attr_reader :contacts
  attr_reader :from_email
  attr_reader :message
  
  def initialize(options)
    @contacts = options[:contacts]
    @from_email = options[:from_email]
    @message = options[:message]
  end

  def send(body)
    sent_message = ''
    contacts.each do |contact|
      to_email = construct_email(contact, is_mms(body))
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

  def construct_email(contact, is_mms)
    carrier = contact[:carrier]
    mms_carrier = carrier.to_s + "mms"
    if is_mms && CARRIERS[mms_carrier]
      carrier = mms_carrier
    end
    "#{contact[:phone]}@#{CARRIERS[carrier.to_sym]}"
  end

  def is_mms(body)
    body.bytes.length > SMS_BYTE_LIMIT
  end
end
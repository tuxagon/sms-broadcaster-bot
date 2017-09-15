require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

require_relative 'app_configurator'
require_relative 'database_connector'
require_relative 'message_sender'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'SMS Broadcaster Bot'.freeze
CLIENT_SECRETS_PATH = 'config/client_secret.json'.freeze
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
  'smsbroadcasterbot.yml').freeze
SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY.freeze

class GmailResponder
  attr_reader :logger
  attr_reader :service
  attr_reader :user_id
  attr_reader :db
  attr_reader :bot

  def initialize(options)
    @logger = AppConfigurator.new.get_logger
    @service = get_service
    @user_id = 'me'
    @bot = options[:bot]
    @db = DatabaseConnector.new
  end

  def forward
    contacts = db.contacts.map { |c| c }
    contacts.each do |contact|
      logger.debug "Searching messages for #{contact[:name]} - #{contact[:phone]}"
      
      # get all messages, which really equates to only showing ids
      result = service.list_user_messages(user_id, q: "from:#{contact[:phone]}")
      return if result.messages.nil?

      # get the details of each message and then forward it to telegram
      result.messages.each do |message|
        message_details = get_message_from_id(message.id)

        # continue if the message is less than a day old
        next if message_details.nil? || too_old?(message_details.internal_date)
        # continue if the message has not already been forwarded
        sent_messages = db.messages_by_contact(contact[:id]).map { |m| m[:message_id] }
        next if sent_messages.include?(message.id)

        send_message(contact, message_details)
      end
    end
  end

  private

  def send_message(contact, message)
    # send message to telegram
    unless message.snippet.empty?
      text = "FROM: #{contact[:name]}\nMESSAGE: #{message.snippet}"
      chat = Struct.new(:id).new(contact[:chat_id])
      MessageSender.new(bot: bot, chat: chat, text: text).send
    end
    
    # mark message as sent
    db.insert_message(contact[:id], message.id)
  end

  def get_message_from_id(id)
    begin
      result = service.get_user_message(user_id, id, format: 'minimal')
      result 
    rescue
      puts "uh oh"
      nil
    end
  end

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def get_service
    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end

  def too_old?(timestamp)
    timestamp <= (Time.new.getutc.to_i - 24*60*60)
  end
end
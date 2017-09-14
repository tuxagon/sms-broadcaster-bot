require 'i18n'
require 'logger'
require 'yaml'

require_relative 'database_connector'

class AppConfigurator
  def configure
    setup_i18n
  end

  def get_token
    YAML.load(IO.read('config/secrets.yml'))['telegram_bot_token']
  end

  def get_smtp
    ['config/app.yml','config/secrets.yml']
      .map { |f| YAML.load(IO.read(f))['smtp'] }
      .reduce({}, :merge)
  end

  def get_from_email
    YAML.load(IO.read('config/secrets.yml'))['from_email']
  end

  def get_logger
    Logger.new($stdout, Logger::DEBUG)
  end

  private 

  def setup_i18n
    I18n.load_path = Dir['config/locales.yml']
    I18n.locale = :en
    I18n.backend.load_translations
  end
end
require 'yaml'

DEV_CONFIG = 'config/dev.yml'.freeze
SECRETS = 'config/secrets.yml'.freeze

# Use http://yaml.org/YAML_for_ruby.html

class Config
  def initialize(file = DEV_CONFIG)
    @config = merge(file, SECRETS)
    puts @config.inspect
  end

  def merge(*files)
    files
      .map { |f| sym_keys(YAML.load_file(f)) }
      .reduce({}, :merge)
  end

  def sym_keys(cfg)
    cfg.reduce({}) do |h, (k, v)|
      h[k.to_sym] = v.is_a?(Hash) ? sym_keys(v) : v
      h
    end
  end

  private :merge, :sym_keys
end

class Bot
  @@config = nil
  def self.run(*args)
    file = args.length > 2 ? args[2] : DEV_CONFIG
    @@config = Config.new(file)
    Bot.new
  end
end

Bot.run(ARGV)
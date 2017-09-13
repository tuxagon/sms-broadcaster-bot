require 'yaml'

DEV_CONFIG = 'config/dev.yml'.freeze
SECRETS = 'config/secrets.yml'.freeze

class Config
  def initialize(file)
    @config_file = File.file?(file.to_s) ? file : DEV_CONFIG
  end

  def get(*keys)
    load.dig(*keys)
  end

  def load
    merge(@config_file, SECRETS)
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

  private :load, :merge, :sym_keys
end
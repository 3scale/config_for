require 'config_for/version'

module ConfigFor
  ReadError = Class.new(StandardError)
  InvalidConfigError = Class.new(StandardError)
  MissingEnvironmentError = Class.new(StandardError)

  autoload :Rails, 'config_for/rails'
  autoload :Sinatra, 'config_for/sinatra'
  autoload :Capistrano, 'config_for/capistrano'

  autoload :Config, 'config_for/config'

  # inspired by https://github.com/rails/rails/commit/9629dea4fb15a948ab4394590fdd946bd9dd4f91

  # Loads yaml file "#{{name}}.yml" from path and gets given environment key.
  # In case the environment is not found, it returns empty hash.
  #
  # @param [Pathname, String] path partial of full path to folder with configs
  # @param [String] name without extension
  # @param [Symbol,String] env key to get from the config
  # @raise [ConfigFor::InvalidConfigError] when the config is invalid YAML
  # @raise [ConfigFor::ReadError] when the config can't be read
  # @return [ActiveSupport::HashWithIndifferentAccess] config file for given env
  # @example Load config in rails
  #  ConfigFor.load_config(Rails.root.join('config'), 'redis', Rails.env)
  def self.load_config(path, name, env)
    config(path, name).fetch(env) { ConfigFor::Config.empty }
  end

  # Same as ConfigFor.load_config but raises exception when environment is not found.
  # Note that this is the preferred way of loading configuration. Also it is used by
  # Rails and Sinatra integrations.
  #
  # @param (see .load_config)
  # @raise (see .load_config)
  # @raise [ConfigFor::MissingEnvironmentError] when the config does not have the environment key
  # @return (see .load_config)
  def self.load_config!(path, name, env)
    config(path, name).fetch(env)
  end

  private

  # @api private
  def self.config(path, name)
    ConfigFor::Config.new(path, name)
  end
end

require 'config_for/integrations'

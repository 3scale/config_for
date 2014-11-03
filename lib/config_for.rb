require 'config_for/version'

module ConfigFor
  InvalidConfig = Class.new(StandardError)
  MissingEnvironment = Class.new(StandardError)

  if defined?(::Rails)
    require 'config_for/rails'
  end

  if defined?(::Sinatra)
    require 'config_for/sinatra'
  end

  if defined?(::Capistrano)
    require 'config_for/capistrano'
  end

  autoload :Config, 'config_for/config'

  # inspired by https://github.com/rails/rails/commit/9629dea4fb15a948ab4394590fdd946bd9dd4f91

  # Loads yaml file "#{{name}}.yml" from path and gets
  #
  # @param [Pathname, String] path partial of full path to folder with configs
  # @param [String] name without extension
  # @param [Symbol,String] env key to get from the config
  # @return [ActiveSupport::HashWithIndifferentAccess] config file for given env
  # @example Load config in rails
  #  ConfigFor.load_config(Rails.root.join('config'), 'redis', Rails.env)
  def self.load_config(path, name, env)
    load_config!(path, name, env) { ConfigFor::Config.empty }
  end

  def self.load_config!(path, name, env, &block)
    config = ConfigFor::Config.new(path, name)
    config.fetch(env, &block)
  end
end

require 'config_for/version'
require 'pathname'

require 'yaml'
require 'erb'
require 'active_support/hash_with_indifferent_access'

module ConfigFor
  if defined?(::Rails)
    require 'config_for/rails'
  end

  if defined?(::Sinatra)
    require 'config_for/sinatra'
  end

  if defined?(::Capistrano)
    require 'config_for/capistrano'
  end

  # inspired by https://github.com/rails/rails/commit/9629dea4fb15a948ab4394590fdd946bd9dd4f91

  # Loads yaml file "#{{name}}.yml" from path and gets
  #
  # @param [Pathname, String] path partial of full path to folder with configs
  # @param [String] name without extension
  # @param [Symbol,String] env key to get from the config
  # @return [ActiveSupport::HashWithIndifferentAccess] config file for given env
  # @raise [RuntimeError] when file does not exist or can't be parsed
  # @example Load config in rails
  #  ConfigFor.load_config(Rails.root.join('config'), 'redis', Rails.env)
  def self.load_config(path, name, env)
    yaml = File.join(path, "#{name}.yml")

    if File.exist?(yaml)
      config = parse_yaml(yaml)[env]
      ActiveSupport::HashWithIndifferentAccess.new(config)
    else
      raise "Could not load configuration. No such file - #{yaml}"
    end
  end

  # Parse and process a yaml file through ERB

  # @param [Pathname, String] full path to yaml file
  # @return [Hash]
  # @raise [RuntimeError] when file can't be parsed
  def self.parse_yaml(file)
    ::YAML.load(::ERB.new(File.read(file)).result) || {}
  rescue ::Psych::SyntaxError => e
    raise "YAML syntax error occurred while parsing #{file}. " \
      "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
      "Error: #{e.message}"
  end
end

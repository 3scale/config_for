require 'config_for'

module ConfigFor
  module Sinatra

    def self.registered(base)
      base.set :config_path, lambda { File.join(base.settings.root, 'config') }
    end

    # Convenience loading of config files.
    #
    # @param [String, Symbol] name the config file to load
    # @return [ActiveSupport::HashWithIndifferentAccess] loaded config file for current environment
    # @raise (see ConfigFor.load_config!)
    # @example
    #   class MyApp < Sinatra::Base
    #     register ConfigFor::Sinatra
    #
    #     set :redis, Redis.new(config_for(:redis))
    #   end
    def config_for(name)
      ConfigFor.load_config!(settings.config_path, name, settings.environment)
    end
  end
end

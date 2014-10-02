module ConfigFor
  module Sinatra

    # Convenience loading of config files
    #
    # @param [String, Symbol] name the config file to load
    # @return [ActiveSupport::HashWithIndifferentAccess] loaded config file for current environment
    # @example
    #   class MyApp < Sinatra::Base
    #     register ConfigFor::Sinatra
    #
    #     set :redis, Redis.new(config_for(:redis))
    #   end
    def config_for(name)
      config = File.join(settings.root, 'config')
      ConfigFor.load_config(config, name, settings.environment)
    end
  end
end

Sinatra.register(ConfigFor::Sinatra)

require 'config_for'

module ConfigFor
  module Rails
    # Convenience loading of config files
    #
    # @param [String, Symbol] name the config file to load
    # @raise (see ConfigFor.load_config!)
    # @return [ActiveSupport::HashWithIndifferentAccess] loaded config file
    # @example in config/production.rb
    #   Rails.application.configure do
    #     config.redis = config_for(:redis)
    #   end
    def config_for(name)
      ConfigFor.load_config!(paths['config'].existent.first, name, ::Rails.env)
    end
  end
end

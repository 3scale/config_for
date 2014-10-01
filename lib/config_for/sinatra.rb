module ConfigFor
  module Sinatra

    def config_for(name)
      config = File.join(settings.root, 'config')
      ConfigFor.load_config(config, name, settings.environment)
    end
  end
end

Sinatra.register(ConfigFor::Sinatra)

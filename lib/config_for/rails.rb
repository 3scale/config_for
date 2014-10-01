module ConfigFor
  module Rails
    def config_for(name)
      ConfigFor.load_config(paths['config'].existent.first, name, ::Rails.env)
    end
  end
end

::Rails::Application.include(ConfigFor::Rails)

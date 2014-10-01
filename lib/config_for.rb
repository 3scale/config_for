require 'config_for/version'

module ConfigFor
  if defined?(Rails)
    require 'config_for/rails'
  end

  if defined?(Sinatra)
    require 'config_for/sinatra'
  end

  if defined?(Capistrano)
    require 'config_for/capistrano'
  end
end

if defined?(::Sinatra)
  require 'config_for/integrations/sinatra'
end

if defined?(::Rails)
  require 'config_for/integrations/rails'
end

if defined?(::Capistrano)
  require 'config_for/capistrano'
end

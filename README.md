# ConfigFor

Framework for generating, uploading and loading config files in Ruby apps.

It offers integrations with Rails and Sinatra.

For generating and uploading configs it uses Capistrano task.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'config_for'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install config_for

## Usage

ConfigFor will automatically load correct integrations for Rails/Sinatra/Capistrano
 when required. If it does not happen automatically, you can include them by hand:

```ruby
require 'config_for/rails'
require 'config_for/sinatra'
require 'config_for/capistrano'
```

### Rails

Rails 4.2 and up provide `config_for` method on `Rails.application`.
ConfigFor backports this for Rails `> 3.0` and `< 4.2`.

So you can use:

```ruby
# config/production.rb
Rails.application.configure do
  config.redis = config_for(:redis) # will load config/redis.yml and get key 'production'
end
```

### Sinatra

Sinatra has no default way of loading configs, so ConfigFor follows the same as Rails.
After loading the integration, Sinatra Classic apps will have the plugin loaded automatically,
but Sinatra Modular apps have to register it by hand.

```ruby
class MyApp < Sinatra::Base
  register ConfigFor::Sinatra

  # loads root + 'config/redis.yml' and gets key of correct 'environment'
  set :redis, Redis.new(config_for(:redis))
end
```

### Capistrano

Capistrano is used to deploy the config to servers. ConfigFor provides task generator
for various configs. First you have to load it:

```ruby
# Capfile
require 'config_for/capistrano'
```

Then you can use it like:

```ruby
set :database_yml, {
  production: {
    host: 'localhost',
    port: 3306
  }
}
ConfigFor::Capistrano::Task.new(:database)
```

Which will generate following tasks:

```shell
cap database                       # Generate config/database.yml
cap database:remove                # Remove config/database.yml from current and shared path
cap database:reset                 # Reset database config
cap database:upload                # Upload config/database.yml to remote servers
```

Also it add hook to run `database` task before `deploy:check:linked_files`.
So the last think you have to do is add `config/database.yml` to `linked_files` variable like:

```ruby
set :linked_files, %w[ config/database.yml ]
```

## Contributing

1. Fork it ( https://github.com/3scale/config_for/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
3. Run tests (`bundle exec rake`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

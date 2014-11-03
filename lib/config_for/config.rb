require 'erb'
require 'yaml'
require 'forwardable'
require 'monitor'
require 'pathname'

require 'active_support/hash_with_indifferent_access'
# HashWithIndifferentAccess needs this core extension to be loaded
require 'active_support/core_ext/hash/indifferent_access'

module ConfigFor
  class Config
    extend Forwardable

    CONFIG_CLASS = ActiveSupport::HashWithIndifferentAccess

    def initialize(path, name)
      @path = path
      @name = name
      @monitor = Monitor.new
      @pathname = Pathname("#{name}.yml").expand_path(path)
    end

    def self.empty
      CONFIG_CLASS.new
    end

    def environments
      config.keys
    end

    def fetch(key, &block)
      config.fetch(key, &block)
    rescue KeyError
      raise ConfigFor::MissingEnvironment, "#{@pathname} contains just #{environments}, not #{key}"
    end

    private

    def config
      @monitor.synchronize do
        if instance_variable_defined?(:@config)
          @config
        else
          @config = convert(parse)
        end
      end
    end

    def convert(hash)
      CONFIG_CLASS.new(hash)
    end

    def read
      @pathname.read
    end

    def parse
      content = read
      erb = ::ERB.new(content).result
      ::YAML.load(erb, @pathname)
    rescue ::Psych::SyntaxError => e
      fail ConfigFor::InvalidConfig, "YAML syntax error occurred while parsing #{content}. Error: #{e.message}"
    end
  end
end

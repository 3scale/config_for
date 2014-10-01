require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
end


begin
  require 'config_for'
  require 'pry'

  task :console do
    Pry.toplevel_binding.pry
  end
rescue LoadError
end

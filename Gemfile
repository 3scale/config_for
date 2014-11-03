source 'https://rubygems.org'

# Specify your gem's dependencies in config_for.gemspec
gemspec development_group: :test

group :test do
  gem 'codeclimate-test-reporter', require: false
  gem 'appraisal'
end


platforms :mri_20, :mri_21 do
  gem 'pry-byebug'
end

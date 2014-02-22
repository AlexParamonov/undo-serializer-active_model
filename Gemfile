source 'https://rubygems.org'

gem "rake"

group :development do
  gem 'pry'
  platforms :ruby_19, :ruby_20 do
    gem 'pry-plus'
  end
end

group :test do
  gem "coveralls", require: false
end

group :test, :development do
  gem "rspec", ">= 3.0.0.beta1"
  gem 'rails', '4.0.2'
  gem "activerecord-jdbcsqlite3-adapter", :platform => :jruby
  gem "sqlite3", :platform => [:ruby, :mswin, :mingw]
  gem 'factory_girl'
  gem 'faker'
  gem "active_model_serializers", "~> 0.8"
end

gemspec

source 'https://rubygems.org'
gemspec

group :test do
  gem 'rails', '4.0.2'
  gem "jdbc-sqlite3", :platform => :jruby
  gem "sqlite3", :platform => [:ruby, :mswin, :mingw]
  gem 'factory_girl'
  gem 'faker'
  gem "pry"
  gem "pry-plus" if "ruby" == RUBY_ENGINE
  gem "coveralls" if !!ENV['CI']
end

platforms :rbx do
  gem 'racc'
  gem 'rubysl', '~> 2.0'
  gem 'psych'
end

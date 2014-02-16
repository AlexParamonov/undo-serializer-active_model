source 'https://rubygems.org'
gemspec

group :test do
  gem 'rails', '4.0.2'
  gem "activerecord-jdbcsqlite3-adapter", :platform => :jruby
  gem "sqlite3", :platform => [:ruby, :mswin, :mingw]
  gem 'factory_girl'
  gem 'faker'
  if !!ENV['CI']
    gem "coveralls"
  else
    gem "pry"
    gem "pry-plus" if "ruby" == RUBY_ENGINE
  end
end

platforms :rbx do
  gem 'racc'
  gem 'rubysl', '~> 2.0'
  gem 'psych'
end

require 'active_record'
$: << File.expand_path('active_record', File.dirname(__FILE__))

require_relative 'factories'

ActiveRecord::Base.establish_connection(
  adapter: "jruby" == RUBY_ENGINE ? "jdbcsqlite3" : "sqlite3",
  database: ":memory:",
  timeout: 5000
)

require_relative "active_record/schema.rb"

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

require_relative 'spec_helper_lite'
require_relative 'rails_app/config/environment'
require_relative 'factories'

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate(Rails.root.join('db', 'migrate').to_s)

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

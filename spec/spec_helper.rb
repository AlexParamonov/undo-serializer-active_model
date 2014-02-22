require_relative "support/ci_helper"
require "undo/serializer/active_model"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

$: << File.expand_path('../lib', File.dirname(__FILE__))

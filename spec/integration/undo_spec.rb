require "spec_helper"
require "undo"
require "support/active_record"
require "user"
require 'undo/integration/shared_undo_integration_examples.rb'

Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new
end

describe Undo do
  let(:object) { create :user }

  include_examples "undo integration"

  it "stores and restores symbols" do
    uuid = subject.store :foo
    expect(subject.restore uuid).to eq :foo
  end
end

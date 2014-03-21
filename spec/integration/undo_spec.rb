require "spec_helper"
require "undo"
require "support/active_record"
require "user"

Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new
end

# TODO: extract to undo_integration test suite gem
describe Undo do
  let(:object) { create :user }
  subject { described_class }

  it "stores and restores object" do
    uuid = subject.store object
    expect(subject.restore uuid).to eq object
  end

  if Undo::VERSION > "0.1.1"
    it "deletes stored object" do
      uuid = subject.store object
      subject.delete uuid
      expect { subject.restore uuid }.to raise_error(KeyError)
    end
  end

  describe "special cases" do
    it "stores and restores nil" do
      uuid = subject.store nil
      expect(subject.restore uuid).to eq nil
    end

    it "stores and restores array" do
      uuid = subject.store [:foo]
      expect(subject.restore uuid).to eq [:foo]
    end
  end
end

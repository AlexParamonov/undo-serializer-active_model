require "spec_helper"

describe Undo::Serializer::ActiveModel::Connector do
  let(:object) { double :object }
  let(:serializer) { subject }

  describe "#primary_key_attributes" do
    let(:attributes) { { uuid: "identifier", foo: :bar, "hello" => "world" } }

    it "extracts object primary key attributes" do
      expect(object).to receive(:primary_key) { "uuid" }

      expect(serializer.primary_key_attributes object, attributes).to eq uuid: "identifier"
    end

    it "redefines primary key attribute names by primary_key_fetcher" do
      serializer = described_class.new primary_key_fetcher: -> object { %w[hello uuid] }

      expect(serializer.primary_key_attributes object, attributes).to eq ({
        hello: "world",
        uuid: "identifier"
      })
    end

    it "use nil value when no primary_key attributes available" do
      allow(object).to receive(:primary_key) { "unknown" }

      expect(serializer.primary_key_attributes object, attributes).to eq unknown: nil
    end

    it "accepts string and symbol as uuid key" do
      allow(object).to receive(:primary_key) { "uuid" }
      expect(serializer.primary_key_attributes object, attributes).to eq uuid: "identifier"
      allow(object).to receive(:primary_key) { :uuid }
      expect(serializer.primary_key_attributes object, attributes).to eq uuid: "identifier"
    end
  end
end

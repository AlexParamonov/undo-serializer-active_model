require "spec_helper"

class FooBarTestObject < OpenStruct
  def attributes; to_h end
end

describe Undo::Serializer::ActiveModel do
  subject { described_class }
  let(:serializer) { subject.new }
  let(:object_class) { FooBarTestObject }
  let(:object) { FooBarTestObject.new }

  # TODO: extract to shared examples
  describe "special cases" do
    cases= [nil, [], [nil, nil], true, false, 1, 1.0, "hello", :world]

    cases.each do |input|
      input_name = input.inspect
      specify "deserialization of serialized #{input_name} returns #{input_name}" do
        expect(serializer.deserialize serializer.serialize(input)).to eq input
      end
    end

    describe "json storage" do
      require "json"
      cases.each do |input|
        input_name = input.inspect

        specify "deserialization of serialized #{input_name} returns #{input_name}" do
          storage = -> object { JSON.load(object.to_json) }
          data = storage.call serializer.serialize(input)
          expect(serializer.deserialize data).to eq input
        end
      end
    end
  end

  describe "options" do
    describe "primary key" do
      it "uses object primary key" do
        object.uuid = "identifier"
        allow(object).to receive(:primary_key) { "uuid" }

        expect(object_class).to receive(:new).with(uuid: "identifier") { double.as_null_object }
        serializer.deserialize serializer.serialize object
      end

      it "uses primary_key_fetcher" do
        object.uuid = "identifier"

        serializer = subject.new primary_key_fetcher: -> object { "uuid" }

        expect(object_class).to receive(:new).with(uuid: "identifier") { double.as_null_object }
        serializer.deserialize serializer.serialize object
      end

      it "use nil value when no primary_key attributes available" do
        allow(object).to receive(:primary_key) { "uuid" }

        expect(object_class).to receive(:new).with(uuid: nil) { double.as_null_object }
        serializer.deserialize serializer.serialize object
      end
    end

    describe "attribute_serializer" do
      let(:attribute_serializer) { double :attribute_serializer }
      let(:serializer) { subject.new attribute_serializer: attribute_serializer }

      it "uses provided attribute serialization" do
        expect(attribute_serializer).to receive(:call).with(object) { [] }
        serializer.serialize object
      end

      context "when nil" do
        let(:attribute_serializer) { proc { nil } }

        it "does not raise" do
          expect { serializer.serialize object }.not_to raise_error
        end
      end
    end

    describe "object_initializer" do
      let(:initializer) { double :initializer }
      let(:serializer) { subject.new object_initializer: initializer }
      before do
        object.id = 1
        object.foo = :bar
      end

      it "uses provided initializer" do
        hash = serializer.serialize object
        expect(initializer).to receive(:call).with(object.class, id: 1) { double.as_null_object }
        serializer.deserialize hash
      end

      context "when nil" do
        let(:initializer) { proc { nil } }

        it "returns nil" do
          hash = serializer.serialize object
          expect(serializer.deserialize hash).to eq nil
        end

        it "does not assigns attributes" do
          hash = serializer.serialize object
          expect{ serializer.deserialize hash }.not_to raise_error
          expect(serializer.deserialize hash).to eq nil
        end
      end
    end

    describe "assign associations" do
      it "uses provided way of assigning associations" do
        associated_object = object_class.new name: "association"
        object.association_name = [associated_object]

        associator = double :associator
        serializer = subject.new associator: associator

        hash = serializer.serialize object, include: :association_name
        expect(associator).to receive(:call) do |object, name, associations|
          expect(associations.map(&:name)).to eq [associated_object.name]
        end
        serializer.deserialize hash
      end
    end

    describe "persist object" do
      it "uses provided way of persisting object" do
        allow(object).to receive(:persisted?) { true }
        persister = double :persister
        serializer = subject.new persister: persister,
                                 object_initializer: proc { object }

        hash = serializer.serialize object
        expect(persister).to receive(:call).with(object)
        serializer.deserialize hash
      end

      it "does not persist new record objects" do
        persister = double :persister
        serializer = subject.new persister: persister,
                                 object_initializer: proc { object }

        allow(object).to receive(:persisted?) { false }

        hash = serializer.serialize object
        expect(persister).not_to receive(:call)
        serializer.deserialize hash
      end
    end
  end
end

require "spec_helper"

describe Undo::Serializer::ActiveModel do
  subject { described_class }
  let(:serializer) { subject.new }
  let(:object) { double :object, attributes: { id: 1, foo: "bar", bar: "baz", hello: "world" } }

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

  describe "custom finder fields" do
    it "uses finder fields to find the object" do
      FooBarTestObject = Class.new
      serializer = subject.new primary_key: [:foo, :bar]
      allow(object).to receive(:class) { FooBarTestObject }

      expect(FooBarTestObject).to receive(:new).with(foo: "bar", bar: "baz") { object.as_null_object }

      hash = serializer.serialize object
      serializer.deserialize hash
    end
  end

  describe "custom serializer" do
    it "uses provided attribute serialization" do
      attribute_serializer = double :attribute_serializer
      serializer = subject.new serialize_attributes: attribute_serializer

      expect(attribute_serializer).to receive(:call).with(object)
      serializer.serialize object
    end

    it "uses provided find_or_initialize deserialization" do
      deserializer = double :find_or_initialize_deserializer
      serializer = subject.new find_or_initialize: deserializer

      hash = serializer.serialize object
      expect(deserializer).to receive(:call).with(object.class, id: 1) { object.as_null_object }
      serializer.deserialize hash
    end

    it "uses provided way of persisting object" do
      persister = double :persister

      deserializer = double :find_or_initialize_deserializer
      allow(deserializer).to receive(:call) { object.as_null_object }
      serializer = subject.new persist: persister, find_or_initialize: deserializer

      hash = serializer.serialize object
      expect(persister).to receive(:call).with(object)
      serializer.deserialize hash
    end
  end

  describe "in place serializer options" do
    specify "#serialize" do
      attribute_serializer = double :attribute_serializer
      serializer = subject.new

      expect(attribute_serializer).to receive(:call).with(object)
      serializer.serialize object,
        serialize_attributes: attribute_serializer
    end

    specify "#deserialize" do
      deserializer = double :find_or_initialize_deserializer
      serializer = subject.new

      hash = serializer.serialize object
      expect(deserializer).to receive(:call).with(object.class, id: 1) { object.as_null_object }
      serializer.deserialize hash,
        find_or_initialize: deserializer
    end
  end

end

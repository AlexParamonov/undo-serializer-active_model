require "spec_helper"

describe Undo::Serializer::ActiveModel do
  subject { described_class }
  let(:serializer) { subject.new }
  let(:object) { double :object }
  let(:am_serializer_method) { :as_json }

  describe "custom finder fields" do
    it "uses finder fields to find the object" do
      FooBarTestObject = Class.new
      serializer = subject.new primary_key: [:foo, :bar]
      allow(object).to receive(:as_json).and_return(foo: "bar", bar: "baz")
      allow(object).to receive(:class) { FooBarTestObject }

      expect(FooBarTestObject).to receive(:new).with(foo: "bar", bar: "baz") { object }

      hash = serializer.serialize object
      serializer.deserialize hash
    end
  end

  describe "custom serializer" do
    it "uses provided serializer" do
      custom_serializer = double :custom_serializer
      serializer = subject.new custom_serializer

      expect(custom_serializer).to receive am_serializer_method
      serializer.serialize object
    end

    it "uses custom serializer source" do
      custom_serializer_source = double :custom_serializer_source
      custom_serializer = double :custom_serializer
      serializer = subject.new serializer: custom_serializer_source

      expect(custom_serializer_source).to receive(:call).with(object) { custom_serializer }
      expect(custom_serializer).to receive am_serializer_method
      serializer.serialize object
    end

    it "has lower priority than providing the serializer directly" do
      custom_serializer_source = double :custom_serializer_source
      custom_serializer = double :custom_serializer

      serializer = subject.new custom_serializer, serializer: custom_serializer_source

      expect(custom_serializer_source).not_to receive(:call)
      expect(custom_serializer).to receive am_serializer_method

      serializer.serialize object
    end
  end

end

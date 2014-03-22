require "virtus"
require_relative "primitive"

module Undo
  module Serializer
    class ActiveModel
      include Virtus.value_object
      values do
        attribute :attribute_serializer, Proc, default: proc { -> object { object.attributes } }
        attribute :persister,            Proc, default: proc { -> object { object.respond_to?(:save!) && object.save! } }
        attribute :primary_key_fetcher,  Proc, default: proc { -> object { object.respond_to?(:primary_key) && object.primary_key || :id }}
        attribute :associator,           Proc, default: proc { -> object, association_name, value { setter = "#{association_name}="; object.respond_to?(setter) && object.send(setter, value) }}
        attribute :object_initializer,   Proc, default: proc { -> object_class, attributes { object_class.respond_to?(:where) && object_class.where(attributes).first || object_class.new(attributes) }}
      end

      def name
        "active_model"
      end

      def serialize(object, options = {})
        return object.map do |record|
          serialize record, options
        end if array? object

        return primitive_serializer.serialize(object) if primitive_serializer.serialize? object
        serialize_object(object, options)
      end

      def deserialize(input, options = {})
        return input.map do |record|
          deserialize record
        end if array? input

        return primitive_serializer.deserialize(input) if primitive_serializer.deserialize? input
        deserialize_object(input)
      end

      private
      attr_reader :config

      def primitive_serializer
        @primitive_serializer ||= Serializer::Primitive.new
      end

      def serialize_object(object, options)
        attributes = serialize_attributes object

        association_names = Array(options[:include])
        associations = {}
        association_names.map do |association|
          associations[association] = serialize(object.public_send association)
        end

        pk_attributes = primary_key_attributes object, attributes
        is_persisted = object.respond_to?(:persisted?) && object.persisted?

        {
          serializer: name,
          attributes: attributes,
          associations: associations,
          meta: {
            pk_attributes: pk_attributes,
            class_name: object.class.name,
            persisted: is_persisted,
          }
        }
      end

      def deserialize_object(object_data)
        object_meta  = object_data.fetch :meta
        associations = object_data.fetch :associations
        attributes   = object_data.fetch :attributes

        with_transaction do
          initialize_object(object_meta).tap do |object|
            return if object.nil?

            attributes.each do |field, value|
              deserialize_field object, field, value
            end

            associations.each do |(association_name, association)|
              associate object, association_name, deserialize(association)
            end

            persist object, object_meta
          end
        end
      end

      def deserialize_field(object, field, value)
        object.send "#{field}=", value # not public_send!
      end

      def primary_key_attributes(object, attributes)
        fields = Array(primary_key_fetcher.call(object)).map(&:to_sym)

        fields.each_with_object({}) do |field, pk_attributes|
          pk_attributes[field] = attributes[field] || attributes[field.to_s]
        end
      end

      def initialize_object(meta)
        object_class = constantize meta.fetch(:class_name)
        pk_attributes = meta.fetch :pk_attributes

        object_initializer.call object_class, pk_attributes
      end

      def persist(object, object_meta)
        persister.call object unless [false, nil, 0, "false"].include? object_meta[:persisted]
      end

      def associate(object, association, associations)
        associator.call object, association, associations
      end

      def serialize_attributes(object)
        attribute_serializer.call(object) || {}
      end

      def with_transaction(&block)
        if defined? ActiveRecord
          ActiveRecord::Base.transaction(&block)
        else
          block.call
        end
      end

      def array?(object)
        object.respond_to?(:map) && ! object.is_a?(Hash)
      end

      private
      def get_option(name, options)
        options.fetch name.to_sym do
          options.fetch name.to_s
        end
      end

      def constantize(class_name)
        class_name.split('::').inject(Kernel) { |object, name| object = object.const_get(name); object }
      end
    end
  end
end

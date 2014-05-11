require_relative "active_model/connector"
require "undo/serializer/primitive"

module Undo
  module Serializer
    class ActiveModel
      def initialize(options = {})
        @connector = self.class.connector.with options
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
      attr_reader :connector

      def primitive_serializer
        @primitive_serializer ||= Serializer::Primitive.new
      end

      def serialize_object(object, options)
        attributes = connector.serialize_attributes object

        association_names = Array(options[:include])
        associations = {}
        association_names.map do |association|
          associations[association] = serialize(object.public_send association)
        end

        pk_attributes = connector.primary_key_attributes object, attributes
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
        object_meta  = connector.get_option :meta, object_data
        associations = connector.get_option :associations, object_data
        attributes   = connector.get_option :attributes, object_data

        with_transaction do
          connector.initialize_object(object_meta).tap do |object|
            return if object.nil?

            attributes.each do |field, value|
              deserialize_field object, field, value
            end

            associations.each do |(association_name, association)|
              connector.associate object, association_name, deserialize(association)
            end

            connector.persist object, object_meta
          end
        end
      end

      def deserialize_field(object, field, value)
        object.send "#{field}=", value # not public_send!
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

    end
  end
end

require "active_support"

module Undo
  module Serializer
    class ActiveModel
      def initialize(*args)
        options = args.extract_options!
        @serialize_attributes_source = options.fetch :serialize_attributes,
          ->(object) { object.attributes }

        @initialize_object_source = options.fetch :find_or_initialize do
          lambda do |object_class, pk_query|
            object_class.respond_to?(:where) && object_class.where(pk_query).first \
              || object_class.new(pk_query)
          end
        end

        @persist_object_source = options.fetch :persist,
          ->(object) { object.respond_to?(:save!) && object.save! }

        @primary_key_fields = options.fetch :primary_key, :id
      end

      def serialize(object, options = {})
        return object.map do |record|
          serialize record, options
        end if array? object

        attributes = serialize_attributes(object) || {}
        associations = {}
        Array(options[:include]).map do |association|
          associations[association] = serialize(object.public_send association)
        end
        pk_attributes = symbolize_keys(attributes).select do |attribute|
          primary_key_fields.include? attribute
        end

        {
          attributes: attributes,
          associations: associations,
          meta: {
            pk_attributes: pk_attributes,
            class_name: object.class.name,
          }
        }
      end

      def deserialize(object)
        return object.map do |record|
          deserialize record
        end if array? object

        hash = symbolize_keys object
        object_meta = hash.fetch :meta
        associations = hash.fetch :associations
        attributes = hash.fetch :attributes

        with_transaction do
          initialize_object(object_meta).tap do |object|
            attributes.each do |field, value|
              deserialize_field object, field, value
            end

            # QUESTION: Set associations? object.association_name = deserialize association ?
            associations.each do |(association_name, association)|
              deserialize association
            end

            persist object
          end
        end
      end

      private
      attr_reader :serialize_attributes_source,
                  :initialize_object_source,
                  :persist_object_source

      def deserialize_field(object, field, value)
        object.send "#{field}=", value # not public_send!
      end

      def initialize_object(meta)
        object_class = constantize meta.fetch(:class_name)
        pk_attributes = meta.fetch :pk_attributes

        find_or_initialize object_class, pk_attributes
      end

      def with_transaction(&block)
        if defined? ActiveRecord
          ActiveRecord::Base.transaction(&block)
        else
          block.call
        end
      end

      def primary_key_fields
        Array(@primary_key_fields)
      end

      def serialize_attributes(*args); serialize_attributes_source.call(*args) end
      def find_or_initialize(*args);   initialize_object_source.call(*args) end
      def persist(*args);              persist_object_source.call(*args) end

      def array?(object)
        object.respond_to?(:map) && ! object.is_a?(Hash)
      end
      # ActiveSupport methods
      def symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          new_key = key.is_a?(String) ? key.to_sym : key
          new_value = value.is_a?(Hash) ? symbolize_keys(value) : value

          result[new_key] = new_value
        end
      end

      def constantize(class_name)
        class_name.split('::').inject(Kernel) { |object, name| object = object.const_get(name); object }
      end
    end
  end
end

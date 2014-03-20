module Undo
  module Serializer
    class ActiveModel
      def initialize(options = {})
        load_options options
      end

      def serialize(object, options = {})
        return object.map do |record|
          serialize record, options
        end if array? object
        return serialize_primitive object if primitive? object

        load_options options

        attributes = serialize_attributes(object) || {}
        associations = {}
        Array(options[:include]).map do |association|
          associations[association] = serialize(object.public_send association)
        end
        pk_attributes = symbolize_keys(attributes).select do |attribute|
          primary_key_fields.include? attribute
        end

        {
          object: {
            attributes: attributes,
            associations: associations,
            meta: {
              pk_attributes: pk_attributes,
              class_name: object.class.name,
            }
          }
        }
      end

      def deserialize(input, options = {})
        return input.map do |record|
          deserialize record
        end if array? input
        hash = symbolize_keys input

        return deserialize_primitive hash.fetch(:primitive) if hash.has_key? :primitive
        object_data = hash.fetch :object

        object_meta  = object_data.fetch :meta
        associations = object_data.fetch :associations
        attributes   = object_data.fetch :attributes

        load_options options

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

      # TODO: extract to primitive serializer
      def serialize_primitive(primitive)
        {
          primitive: {
            object: primitive,
            class_name: primitive.class.name
          }
        }
      end

      def primitive?(object)
        case object
        when
          Integer,
          Float,
          Symbol,
          String,
          true,
          false,
          nil
          then true
        when Array, Hash then object.empty?
        else false
        end
      end

      def deserialize_primitive(primitive)
        primitive_class = primitive.fetch(:class_name).to_s
        object = primitive.fetch(:object)

        return case primitive_class
          when "Fixnum"     then object.to_i
          when "Symbol"     then object.to_sym
          when "TrueClass"  then true
          when "FalseClass" then false
          when "NilClass"   then nil
          else Kernel.send primitive_class, object
          end
      end

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

      def load_options(options)
        @serialize_attributes_source = options.fetch :serialize_attributes, @serialize_attributes_source ||
          ->(object) { object.attributes }

        @initialize_object_source = options.fetch :find_or_initialize, @initialize_object_source ||
          ->(object_class, pk_query) { object_class.respond_to?(:where) && object_class.where(pk_query).first || object_class.new(pk_query) }

        @persist_object_source = options.fetch :persist, @persist_object_source ||
          ->(object) { object.respond_to?(:save!) && object.save! }

        @primary_key_fields = options.fetch :primary_key, @primary_key_fields || :id
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

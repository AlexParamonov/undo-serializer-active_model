require "virtus"

module Undo
  module Serializer
    class ActiveModel
      include Virtus.value_object
      values do
        attribute :attribute_serializer, Proc, default: proc { -> object { object.attributes } }
        attribute :persister, Proc, default: proc { -> object { object.respond_to?(:save!) && object.save! } }
        attribute :associator, Proc, default: proc {
          -> object, association, value do
            object.respond_to?("#{association}=") && object.send("#{association}=", value)
          end
        }
        attribute :object_initializer, Proc, default: proc {
          -> object_class, pk_attributes do
               object_class.respond_to?(:where) && object_class.where(pk_attributes).first \
            || object_class.new(pk_attributes)
          end
        }
        attribute :primary_key_fetcher, Proc, default: proc {
          -> object { object.respond_to?(:primary_key) && object.primary_key || :id }
        }
      end


      def serialize(object, options = {})
        return object.map do |record|
          serialize record, options
        end if array? object
        return serialize_primitive object if primitive? object

        attributes = serialize_attributes object
        pk_attributes = primary_key_attributes object, attributes

        association_names = Array(options[:include])
        associations = {}
        association_names.map do |association|
          associations[association] = serialize(object.public_send association)
        end

        is_persisted = object.respond_to?(:persisted?) && object.persisted?

        {
          object: {
            attributes: attributes,
            associations: associations,
            meta: {
              pk_attributes: pk_attributes,
              class_name: object.class.name,
              persisted: is_persisted,
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

      private
      attr_reader :config

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

      def primary_key_attributes(object, attributes)
        fields = Array(primary_key_fetcher.call(object)).map!(&:to_sym)

        pk_attributes = {}
        fields.each do |field|
          pk_attributes[field] = nil
        end

        pk_attributes.merge! attributes.select { |attribute| fields.include? attribute }
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
        symbolize_keys attribute_serializer.call(object) || {}
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

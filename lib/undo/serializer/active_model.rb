require "active_support"

module Undo
  module Serializer
    class ActiveModel
      def initialize(*args)
        options = args.extract_options!
        @serializer = args.first
        @serializer_source = options.fetch :serializer,
          ->(object) { object }

        @initialize_object_source = options.fetch :find_or_initialize do
          ->(object_class, pk_query) do
            object_class.respond_to?(:where) && object_class.where(pk_query).first || object_class.new(pk_query)
          end
        end

        @persist_object_source = options.fetch :persist,
          ->(object) { object.respond_to?(:save!) && object.save! }

        @primary_key_fields = options.fetch :primary_key, :id
      end

      def serialize(object, options = {})
        return object.map do |record|
          serialize record, options
        end if object.respond_to? :map

        associations = Array(options.fetch(:include, []))
        serialized_object = serializer(object).as_json.tap do |hash|
          associations.each do |association|
            hash[association] = serialize(object.public_send association)
          end
        end

        {
          attributes: serialized_object,
          object: {
            primary_key: primary_key_fields,
            class_name: object.class.name,
            associations: associations,
          }
        }
      end

      def deserialize(object)
        return object.map do |record|
          deserialize record
        end if object.respond_to?(:map) && ! object.is_a?(Hash)

        hash = symbolize_keys object
        object_meta = hash.fetch :object
        associations = object_meta.fetch(:associations).map(&:to_sym)
        attributes = hash.fetch :attributes

        with_transaction do
          initialize_object(object_meta, attributes).tap do |object|
            attributes.each do |field, value|
              if associations.include?(field)
                deserialize value
              else
                deserialize_field object, field, value
              end
            end

            persist object
          end
        end
      end

      private
      attr_reader :serializer_source, :initialize_object_source, :persist_object_source

      def serializer(object)
        @serializer || serializer_source.call(object)
      end

      def deserialize_field(object, field, value)
        return if primary_key_fields.include? field
        object.send "#{field}=", value # not public_send!
      end

      def initialize_object(meta, attributes)
        pk_query = attributes.select { |attribute| primary_key_fields.include? attribute }
        object_class = constantize meta.fetch(:class_name)

        find_or_initialize object_class, pk_query
      end

      def primary_key_fields
        Array(@primary_key_fields)
      end

      def persist(*args)
        persist_object_source.call *args
      end

      def find_or_initialize(*args)
        initialize_object_source.call *args
      end

      def with_transaction(&block)
        if defined? ActiveRecord
          ActiveRecord::Base.transaction(&block)
        else
          block.call
        end
      end

      # ActiveSupport metods
      def symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        }
      end

      def constantize(class_name)
        class_name.split('::').inject(Kernel) { |object, name| object = object.const_get(name); object }
      end
    end
  end
end

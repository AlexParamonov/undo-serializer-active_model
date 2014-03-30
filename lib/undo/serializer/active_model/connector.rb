require "virtus"

module Undo
  module Serializer
    class ActiveModel
      def self.connector
        @config ||= Connector.new
      end

      private
      class Connector
        include Virtus.value_object
        values do
          attribute :attribute_serializer, Proc, default: proc { -> object { object.attributes } }
          attribute :persister,            Proc, default: proc { -> object { object.respond_to?(:save!) && object.save! } }
          attribute :primary_key_fetcher,  Proc, default: proc { -> object { object.respond_to?(:primary_key) && object.primary_key || :id }}
          attribute :associator,           Proc, default: proc { -> object, association_name, value { setter = "#{association_name}="; object.respond_to?(setter) && object.send(setter, value) }}
          attribute :object_initializer,   Proc, default: proc { -> object_class, attributes { object_class.respond_to?(:where) && object_class.where(attributes).first || object_class.new(attributes) }}
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

        def constantize(class_name)
          class_name.split('::').inject(Kernel) { |object, name| object = object.const_get(name); object }
        end
      end
    end
  end
end

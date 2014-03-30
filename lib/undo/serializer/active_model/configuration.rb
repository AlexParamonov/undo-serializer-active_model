require "virtus"

module Undo
  module Serializer
    class ActiveModel
      def self.config
        @config ||= Configuration.new
      end

      private
      class Configuration
        include Virtus.value_object
        values do
          attribute :attribute_serializer, Proc, default: proc { -> object { object.attributes } }
          attribute :persister,            Proc, default: proc { -> object { object.respond_to?(:save!) && object.save! } }
          attribute :primary_key_fetcher,  Proc, default: proc { -> object { object.respond_to?(:primary_key) && object.primary_key || :id }}
          attribute :associator,           Proc, default: proc { -> object, association_name, value { setter = "#{association_name}="; object.respond_to?(setter) && object.send(setter, value) }}
          attribute :object_initializer,   Proc, default: proc { -> object_class, attributes { object_class.respond_to?(:where) && object_class.where(attributes).first || object_class.new(attributes) }}
        end
      end
    end
  end
end

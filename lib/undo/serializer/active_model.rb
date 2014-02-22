require "active_support"

module Undo
  module Serializer
    class ActiveModel
      def initialize(*args)
        options = args.extract_options!
        @serializer = args.first
        @serializer_source = options.fetch :serializer,
          ->(object) { object.active_model_serializer.new object }
      end

      def serialize(object)
        serializer(object).as_json
      end

      def deserialize(hash)
        hash.each do |object_class, data|
          next unless data.is_a? Hash
          data.stringify_keys!

          object_class = object_class.to_s.camelize.constantize
          object = object_class.where(id: data.fetch("id")).first_or_initialize

          data.each do |field, value|
            next if "id" == field && object.persisted?
            _, association = field.to_s.split("___")
            if association
              deserialize_association(association, value)
            else
              object.send "#{field}=", value # not public_send!
            end
          end

          object.save!
          return object
        end
      end

      private
      attr_reader :serializer_source

      def serializer(object)
        @serializer ||= serializer_source.call object
      end

      def deserialize_association(association, values)
        Array.wrap(values).each do |value|
          deserialize(association.singularize => value)
        end
      end
    end
  end
end

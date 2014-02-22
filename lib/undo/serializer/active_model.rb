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
        object_name, data = hash.first
        return unless data.is_a? Hash
        data.stringify_keys!

        ActiveRecord::Base.transaction do
          initialize_object(object_name, data).tap do |object|
            data.each do |field, value|
              next if "id" == field && object.persisted?

              case field
              when /___(.*)/ then deserialize_association object, $1,    value
              else                deserialize_field       object, field, value
              end
            end

            object.save!
          end
        end

      end

      private
      attr_reader :serializer_source

      def serializer(object)
        @serializer ||= serializer_source.call object
      end

      def deserialize_association(object, association, values)
        Array.wrap(values).each do |value|
          deserialize association.singularize => value
        end
      end

      def deserialize_field(object, field, value)
        object.send "#{field}=", value # not public_send!
      end

      def initialize_object(object_name, data)
        id = data.fetch "id"
        object_class = object_name.to_s.camelize.constantize
        object_class.where(id: id).first || object_class.new(id: id)
      end
    end
  end
end

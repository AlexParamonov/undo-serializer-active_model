module Undo
  module Serializer
    class Primitive
      def name
        "primitive"
      end

      def serialize(primitive, options = {})
        {
          serializer: name,
          object: primitive,
          class_name: primitive.class.name
        }
      end

      def deserialize(primitive_data, options = {})
        primitive_class = get_option :class_name, primitive_data
        object = get_option :object, primitive_data

        return case primitive_class
               when "Fixnum"     then object.to_i
               when "Symbol"     then object.to_sym
               when "TrueClass"  then true
               when "FalseClass" then false
               when "NilClass"   then nil
               else Kernel.send primitive_class, object
               end
      end

      def serialize?(object)
        case object
        when Integer, Float, Symbol, String, true, false, nil then true
        when Array, Hash then object.empty?
        else false
        end
      end

      def deserialize?(hash)
        name == (hash[:serializer] || hash["serializer"])
      end

      private
      def get_option(name, options)
        options.fetch name.to_sym do
          options.fetch name.to_s
        end
      end
    end

  end
end

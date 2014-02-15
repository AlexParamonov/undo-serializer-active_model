require "active_model_serializers"

class UserSerializer < ::ActiveModel::Serializer
  attributes *User.attribute_names.map(&:to_sym)
  has_many :roles, :key => :has_many___roles
end


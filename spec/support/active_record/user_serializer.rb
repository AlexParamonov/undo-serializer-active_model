require "active_model_serializers"

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email
  has_many :roles, key: :has_many___roles
end

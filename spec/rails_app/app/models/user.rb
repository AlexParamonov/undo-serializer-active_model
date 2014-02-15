class User < ActiveRecord::Base
  has_many :roles, dependent: :delete_all
end

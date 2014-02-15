FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :role do
    name { Faker::Name.name }
    user { create :user }
  end
end

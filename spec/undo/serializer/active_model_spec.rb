require "spec_helper_rails"
require "undo/serializer/active_model"

describe Undo::Serializer::ActiveModel do
  subject { described_class }
  let(:serializer) { described_class.new UserSerializer }
  let(:user) { create :user }

  it "restores object" do
    hash = serializer.serialize user
    user.destroy
    restored_user = serializer.deserialize hash

    expect(restored_user).to eq user
    expect(user).not_to be_persisted
    expect(restored_user).to be_persisted
  end

  it "restores object and associations" do
    roles = create_list :role, 3, user: user
    hash = serializer.serialize user
    user.destroy
    restored_user = serializer.deserialize hash

    expect(restored_user).to eq user
    expect(restored_user.roles).to eq roles
  end

  it "reverts changes to object" do
    hash = serializer.serialize user
    user.name = "Changed"
    user.save!

    restored_user = serializer.deserialize hash

    expect(restored_user.name).not_to eq "Changed"
    expect(restored_user).to eq user.reload
  end

  describe "find model serializer" do
    it "detects serializer for a model" do
      serializer = subject.new
      expect(UserSerializer).to receive(:new)
      serializer.serialize(user)
    end

    it "uses provided serializer" do
      model_serializer = double :model_serializer
      serializer = subject.new model_serializer
      expect(model_serializer).to receive(:new)
      serializer.serialize(user)
    end
  end
end

require "spec_helper"
require "support/active_record"
require "user"
require "role"

describe Undo::Serializer::ActiveModel do
  subject { described_class }
  let(:serializer) { subject.new }
  let(:user) { create :user }

  it "restores object" do
    hash = serializer.serialize user
    user.delete
    restored_user = serializer.deserialize hash

    expect(restored_user).to eq user
    expect(user).not_to be_persisted
    expect(restored_user).to be_persisted
  end

  describe "not persisted object" do
    let(:user) { build :user }

    it "restores object" do
      hash = serializer.serialize user
      restored_user = serializer.deserialize hash

      expect(restored_user.attributes).to eq user.attributes
      expect(restored_user).not_to be_persisted
    end

    it "restores provided associations" do
      roles = build_list :role, 3
      user.roles = roles
      hash = serializer.serialize user, include: :roles

      restored_user = serializer.deserialize hash

      expect(restored_user).not_to be_persisted
      expect(restored_user.roles.map(&:attributes)).to match roles.map(&:attributes)
    end
  end

  describe "associations" do
    it "restores provided associations" do
      roles = create_list :role, 3, user: user
      hash = serializer.serialize user, include: :roles
      user.delete

      restored_user = serializer.deserialize hash

      expect(restored_user).to eq user
      expect(restored_user.roles).to eq roles
    end
  end

  it "reverts changes to object" do
    hash = serializer.serialize user
    user.name = "Changed"
    user.save!

    restored_user = serializer.deserialize hash

    expect(restored_user.name).not_to eq "Changed"
    expect(restored_user).to eq user.reload
  end

  describe "array of objects" do
    it "restores a collection" do
      users = create_list :user, 3
      array = serializer.serialize users, include: :roles
      users.each &:delete

      restored_users = serializer.deserialize array
      expect(restored_users).to eq users
    end
  end

  describe "json store" do
    it "restores object" do
      hash = serializer.serialize user
      hash = hash.to_json
      user.delete
      restored_user = serializer.deserialize JSON.load(hash)

      expect(restored_user).to eq user
      expect(user).not_to be_persisted
      expect(restored_user).to be_persisted
    end
  end
end

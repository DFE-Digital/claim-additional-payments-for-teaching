require "rails_helper"

RSpec.describe Reminder, type: :model do
  subject { described_class.new }

  context "that has a email address" do
    it "validates that the value is in the correct format" do
      expect(build(:reminder, email_address: "notan email@address.com")).not_to be_valid
      expect(build(:reminder, email_address: "david.tau.2020.gb@example.com")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(build(:reminder, email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  context "that has a full name" do
    it "validates the length of name is 100 characters or less" do
      expect(build(:reminder, full_name: "Name " * 50)).not_to be_valid
      expect(build(:reminder, full_name: "John")).to be_valid
    end
  end

  context "when saving in the 'personal-details' validation context" do
    it "validates the presence of full_name" do
      expect(build(:reminder, full_name: nil)).not_to be_valid(:"personal-details")
      expect(build(:reminder, full_name: "Miss Sveta Bond-Areemev")).to be_valid(:"personal-details")
    end

    it "validates the presence of email_address" do
      expect(build(:reminder, email_address: nil)).not_to be_valid(:"personal-details")
    end
  end
end

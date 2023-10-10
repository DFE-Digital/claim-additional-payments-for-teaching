require "rails_helper"

RSpec.describe DfeIdentity::UserInfo, type: :model do
  subject(:user_info) { described_class.new }

  it { is_expected.to validate_presence_of(:trn) }
  it { is_expected.to validate_presence_of(:birthdate) }
  it { is_expected.to validate_presence_of(:given_name) }
  it { is_expected.to validate_presence_of(:family_name) }
  it { is_expected.to validate_presence_of(:ni_number) }
  it { is_expected.to validate_presence_of(:trn_match_ni_number) }

  describe ".validated?" do
    context "when all required attribute values are present" do
      subject(:user_info) do
        described_class.validated?(
          trn: "1234567",
          birthdate: "1940-01-01",
          given_name: "Kelsie",
          family_name: "Oberbrunner",
          ni_number: "AB123456C",
          trn_match_ni_number: "true"
        )
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when a required attribute value is missing" do
      subject(:user_info) do
        described_class.validated?(
          trn: "1234567",
          birthdate: "1940-01-01",
          given_name: "Kelsie",
          family_name: "Oberbrunner",
          ni_number: "AB123456C",
          trn_match_ni_number: nil
        )
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when trn_match_ni_number is not true" do
      subject(:user_info) do
        described_class.validated?(
          trn: "1234567",
          birthdate: "1940-01-01",
          given_name: "Kelsie",
          family_name: "Oberbrunner",
          ni_number: "AB123456C",
          trn_match_ni_number: "false"
        )
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when unknown attributes are present" do
      subject(:user_info) do
        described_class.validated?(
          trn: "1234567",
          birthdate: "1940-01-01",
          given_name: "Kelsie",
          family_name: "Oberbrunner",
          ni_number: "AB123456C",
          trn_match_ni_number: "true",
          unknown_attribute: "value"
        )
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when attributes are missing" do
      subject(:user_info) do
        described_class.validated?(
          trn: "1234567",
          birthdate: "1940-01-01",
          given_name: "Kelsie",
          family_name: "Oberbrunner",
          ni_number: "AB123456C"
        )
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when attributes are empty" do
      subject(:user_info) do
        described_class.validated?(nil)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end

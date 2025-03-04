require "rails_helper"

RSpec.describe Admin::AmendmentForm, type: :model do
  describe "#date_of_birth" do
    context "when out of range ie invalid date" do
      subject do
        described_class.new(
          "date_of_birth(1i)": "13",
          "date_of_birth(2i)": "13",
          "date_of_birth(3i)": "1970"
        )
      end

      it "set date_of_birth to nil" do
        expect(subject.date_of_birth).to be_nil
      end
    end
  end

  describe "validations" do
    let(:claim) { build(:claim, :submitted) }

    subject { described_class.new(claim:) }

    it { is_expected.to validate_presence_of(:date_of_birth).with_message("Enter a date of birth") }
  end
end

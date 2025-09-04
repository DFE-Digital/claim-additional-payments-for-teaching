require "rails_helper"

RSpec.describe Admin::Tasks::MatchingDetailsForm, type: :model do
  describe "#validations" do
    describe "#passed when no option selected" do
      subject do
        described_class.new(passed: nil)
      end

      it "returns correct error message" do
        subject.valid?
        expect(subject.errors[:passed]).to eql(["Select yes if this claim is valid"])
      end
    end
  end
end

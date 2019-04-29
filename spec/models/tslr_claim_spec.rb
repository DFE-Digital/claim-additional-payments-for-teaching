require "rails_helper"

RSpec.describe TslrClaim, type: :model do
  context "when saving in the “qts-year” validation context" do
    let(:custom_validation_context) { :"qts-year" }

    it "validates the qts_award_year is one of the allowable values" do
      expect(TslrClaim.new).not_to be_valid(custom_validation_context)
      expect(TslrClaim.new(qts_award_year: "123")).not_to be_valid(custom_validation_context)

      TslrClaim::VALID_QTS_YEARS.each do |academic_year|
        expect(TslrClaim.new(qts_award_year: academic_year)).to be_valid(custom_validation_context)
      end
    end
  end
end

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

  context "when saving in the “claim-school” validation context" do
    let(:custom_validation_context) { :"claim-school" }

    it "it validates the claim_school" do
      expect(TslrClaim.new).not_to be_valid(custom_validation_context)
      expect(TslrClaim.new(claim_school: schools(:penistone_grammar_school))).to be_valid(custom_validation_context)
    end
  end

  describe "#employment_status" do
    it "provides an enum that captures the claiment’s employment status" do
      claim = TslrClaim.new

      claim.employment_status = :claim_school
      expect(claim.employed_at_claim_school?).to eq true
      expect(claim.employed_at_different_school?).to eq false
      expect(claim.employed_at_no_school?).to eq false
    end

    it "rejects invalid employment statuses" do
      expect { TslrClaim.new(employment_status: :nonsense) }.to raise_error(ArgumentError)
    end
  end
end

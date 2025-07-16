require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::Eligibility do
  describe "#provider_verification_status" do
    let(:eligibility) { build(:further_education_payments_eligibility) }

    context "when no provider verification fields are set" do
      it "returns 'not_started'" do
        expect(eligibility.provider_verification_status).to eq("not_started")
      end
    end

    context "when any provider verification field is set" do
      it "returns 'in_progress' when teaching_responsibilities is set" do
        eligibility.provider_verification_teaching_responsibilities = true
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when in_first_five_years is set" do
        eligibility.provider_verification_in_first_five_years = false
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when teaching_qualification is set" do
        eligibility.provider_verification_teaching_qualification = "yes"
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when contract_type is set" do
        eligibility.provider_verification_contract_type = "permanent"
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when contract_covers_full_academic_year is set" do
        eligibility.provider_verification_contract_covers_full_academic_year = true
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when taught_at_least_one_academic_term is set" do
        eligibility.provider_verification_taught_at_least_one_academic_term = true
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when performance_measures is set" do
        eligibility.provider_verification_performance_measures = true
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end

      it "returns 'in_progress' when disciplinary_action is set" do
        eligibility.provider_verification_disciplinary_action = false
        expect(eligibility.provider_verification_status).to eq("in_progress")
      end
    end
  end

  describe "#provider_verification_started?" do
    let(:eligibility) { build(:further_education_payments_eligibility) }

    it "returns false when no provider verification fields are set" do
      expect(eligibility.provider_verification_started?).to be false
    end

    it "returns true when at least one provider verification field is set" do
      eligibility.provider_verification_teaching_responsibilities = true
      expect(eligibility.provider_verification_started?).to be true
    end
  end
end

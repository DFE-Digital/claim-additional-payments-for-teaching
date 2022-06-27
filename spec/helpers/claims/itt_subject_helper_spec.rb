require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  let(:ecp_trainee_teacher_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
  let(:lup_trainee_teacher_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

  let(:ecp_trainee_teacher_claim) { build(:claim, :first_lup_claim_year, eligibility: ecp_trainee_teacher_eligibility) }
  let(:lup_trainee_teacher_claim) { build(:claim, :first_lup_claim_year, eligibility: lup_trainee_teacher_eligibility) }

  describe "#subject_symbols" do
    context "trainee teacher" do
      subject { helper.subject_symbols(CurrentClaim.new(claims: [ecp_trainee_teacher_claim, lup_trainee_teacher_claim])) }

      it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
    end

    # this delegates to another class which checks more combinations
    context "non-trainee example" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

      let(:eligible_ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year) }
      let(:eligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, itt_academic_year: itt_year) }

      let(:eligible_ecp_claim) { build(:claim, :first_lup_claim_year, eligibility: eligible_ecp_eligibility) }
      let(:eligible_lup_claim) { build(:claim, :first_lup_claim_year, eligibility: eligible_lup_eligibility) }

      subject { helper.subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

      it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
    end
  end

  describe "#subjects_to_sentence" do
    context "trainee teacher" do
      subject { helper.subjects_to_sentence(CurrentClaim.new(claims: [ecp_trainee_teacher_claim, lup_trainee_teacher_claim])) } # check calls

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end
  end
end

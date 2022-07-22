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
    let(:ecp_claim) { build(:claim, :first_lup_claim_year, eligibility: ecp_eligibility) }
    let(:lup_claim) { build(:claim, :first_lup_claim_year, eligibility: lup_eligibility) }
    let(:academic_year_2019) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
    let(:academic_year_2020) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

    subject { helper.subjects_to_sentence(CurrentClaim.new(claims: [ecp_claim, lup_claim])) }

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "chosen LUP-only subject" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2020, eligible_itt_subject: :computing) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2020, eligible_itt_subject: :computing) }

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "chosen what's both an ECP and LUP subject" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2020, eligible_itt_subject: :mathematics) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2020, eligible_itt_subject: :mathematics) }

      it { is_expected.to eq("chemistry, computing, languages, mathematics or physics") }
    end

    context "chosen ECP-only subject for an ITT year where the options are Chemistry, Languages, Mathematics and Physics" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2020, eligible_itt_subject: :foreign_languages) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, itt_academic_year: academic_year_2020, eligible_itt_subject: :foreign_languages) }

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end

    context "chosen ECP-only subject for an ITT year where the only ECP subject is Mathematics" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :common_eligible_attributes, itt_academic_year: academic_year_2019, eligible_itt_subject: :mathematics) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, itt_academic_year: academic_year_2019, eligible_itt_subject: :mathematics) }

      it { is_expected.to eq("mathematics") }
    end
  end
end

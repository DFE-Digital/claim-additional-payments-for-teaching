require "rails_helper"
require "ineligibility_reason_checker"

RSpec.describe IneligibilityReasonChecker do
  let(:academic_year) { AcademicYear.new(2022) }
  let(:none_of_the_above_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new("None")) }
  let(:ecp_claim) { build(:claim, policy: Policies::EarlyCareerPayments, academic_year:, eligibility: ecp_eligibility, logged_in_with_tid:, qualifications_details_check:) }
  let(:lup_claim) { build(:claim, policy: Policies::LevellingUpPremiumPayments, academic_year:, eligibility: lup_eligibility, logged_in_with_tid:, qualifications_details_check:) }
  let(:logged_in_with_tid) { nil }
  let(:qualifications_details_check) { nil }

  let(:school_eligible_for_ecp_and_lup) { build(:school, :early_career_payments_eligible, :levelling_up_premium_payments_eligible) }
  let(:school_eligible_for_ecp_but_not_lup) { build(:school, :early_career_payments_eligible) }
  let(:school_ineligible_for_both_ecp_and_lup) { build(:school, :early_career_payments_ineligible) }

  before { create(:journey_configuration, :additional_payments, current_academic_year: academic_year) }

  # sanity check of factories
  specify { expect(Policies::EarlyCareerPayments::SchoolEligibility.new(school_eligible_for_ecp_but_not_lup)).to be_eligible }
  specify { expect(Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school_eligible_for_ecp_but_not_lup)).not_to be_eligible }

  specify { expect(Policies::EarlyCareerPayments::SchoolEligibility.new(school_ineligible_for_both_ecp_and_lup)).not_to be_eligible }
  specify { expect(Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school_ineligible_for_both_ecp_and_lup)).not_to be_eligible }

  let(:current_claim) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }

  describe "#reason" do
    subject { described_class.new(current_claim).reason }

    context "school ineligible for both ECP and LUP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, current_school: school_ineligible_for_both_ecp_and_lup) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, current_school: school_ineligible_for_both_ecp_and_lup) }

      it { is_expected.to eq(:current_school) }
    end

    context "short-term supply teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :short_term_supply_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :short_term_supply_teacher) }

      it { is_expected.to eq(:generic) }
    end

    context "agency supply teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :agency_supply_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :agency_supply_teacher) }

      it { is_expected.to eq(:generic) }
    end

    context "short-term agency supply teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :short_term_agency_supply_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :short_term_agency_supply_teacher) }

      it { is_expected.to eq(:generic) }
    end

    context "formal action" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, subject_to_formal_performance_action: true) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, subject_to_formal_performance_action: true) }

      it { is_expected.to eq(:generic) }
    end

    context "disciplinary action" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, subject_to_disciplinary_action: true) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, subject_to_disciplinary_action: true) }

      it { is_expected.to eq(:generic) }
    end

    context "formal and disciplinary action" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, subject_to_formal_performance_action: true, subject_to_disciplinary_action: true) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, subject_to_formal_performance_action: true, subject_to_disciplinary_action: true) }

      it { is_expected.to eq(:generic) }
    end

    context "eligible for both ECP and LUP but 'None of the above' ITT year" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_and_lup, itt_academic_year: none_of_the_above_academic_year) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_and_lup, itt_academic_year: none_of_the_above_academic_year) }

      it { is_expected.to eq(:generic) }
    end

    context "eligible for ECP only but 'None of the above' ITT year" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: none_of_the_above_academic_year) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, itt_academic_year: none_of_the_above_academic_year) }

      it { is_expected.to eq(:ecp_only_teacher_with_ineligible_itt_year) }
    end

    context "eligible for LUP only but insufficient teaching" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible, :insufficient_teaching) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :insufficient_teaching) }

      it { is_expected.to eq(:would_be_eligible_for_lup_only_except_for_insufficient_teaching) }
    end

    context "eligible for ECP only but insufficient teaching" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :insufficient_teaching) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, :insufficient_teaching) }

      it { is_expected.to eq(:would_be_eligible_for_ecp_only_except_for_insufficient_teaching) }
    end

    context "eligible for both ECP and LUP except for insufficient teaching" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :insufficient_teaching) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :insufficient_teaching) }

      it { is_expected.to eq(:would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching) }
    end

    context "bad ITT subject and no degree" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, eligible_itt_subject: :none_of_the_above) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :no_relevant_degree, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:lack_both_valid_itt_subject_and_degree) }
    end

    context "non-LUP school, only given one ITT subject option but does not take the ECP subject option for 2018" do
      # This spec might need to change for future policy years
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year, current_school: school_eligible_for_ecp_but_not_lup, eligible_itt_subject: :none_of_the_above) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :ineligible_school, itt_academic_year: itt_year, current_school: school_eligible_for_ecp_but_not_lup, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:bad_itt_year_for_ecp) }
    end

    context "non-LUP school, only given one ITT subject option but does not take the ECP subject option for 2019" do
      # This spec might need to change for future policy years
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year, current_school: school_eligible_for_ecp_but_not_lup, eligible_itt_subject: :none_of_the_above) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, itt_academic_year: itt_year, current_school: school_eligible_for_ecp_but_not_lup, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:bad_itt_year_for_ecp) }
    end

    context "non-LUP school, given multiple ITT subject options but chose 'none of the above'" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_but_not_lup, itt_academic_year: itt_year, eligible_itt_subject: :none_of_the_above) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_but_not_lup, itt_academic_year: itt_year, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:bad_itt_subject_for_ecp) }
    end

    context "trainee teacher at an ECP-only school" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :trainee_teacher, current_school: school_eligible_for_ecp_but_not_lup) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :ineligible_school, :trainee_teacher, current_school: school_eligible_for_ecp_but_not_lup) }

      it { is_expected.to eq(:ecp_only_trainee_teacher) }
    end

    context "trainee teacher in an LUP school who isn't training to teach an eligible subject nor has a relevant degree" do
      let(:school) { build(:school, :levelling_up_premium_payments_eligible) }
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, :trainee_teacher, eligible_itt_subject: :foreign_languages, current_school: school) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :trainee_teacher, :no_relevant_degree, eligible_itt_subject: :foreign_languages, current_school: school) }

      it { is_expected.to eq(:trainee_teaching_lacking_both_valid_itt_subject_and_degree) }
    end

    context "non-LUP school and no ECP subjects for ITT year" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_but_not_lup, itt_academic_year: itt_year) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, current_school: school_eligible_for_ecp_but_not_lup, itt_academic_year: itt_year) }

      it { is_expected.to eq(:no_ecp_subjects_that_itt_year) }
    end

    context "trainee teacher in last policy year" do
      let(:school) { build(:school, :combined_journey_eligibile_for_all) }
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher, current_school: school) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher, current_school: school) }
      let(:ecp_claim) { build(:claim, policy: Policies::EarlyCareerPayments, academic_year: "2024/2025", eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, policy: Policies::LevellingUpPremiumPayments, academic_year: "2024/2025", eligibility: lup_eligibility) }

      it { is_expected.to eq(:trainee_in_last_policy_year) }
    end

    context "when DQT-derived qualifications data indicates the user is ineligible" do
      let(:qualifications_details_check) { true }
      let(:logged_in_with_tid) { true }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, eligible_itt_subject: :none_of_the_above) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :no_relevant_degree, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:dqt_data_ineligible) }
    end
  end
end

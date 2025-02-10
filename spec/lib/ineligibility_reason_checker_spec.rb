require "rails_helper"
require "ineligibility_reason_checker"

RSpec.describe IneligibilityReasonChecker do
  let(:academic_year) { AcademicYear.new(2022) }
  let(:none_of_the_above_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new("None")) }
  let(:logged_in_with_tid) { nil }
  let(:qualifications_details_check) { nil }

  let(:school_eligible_for_ecp_and_lup) { create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_eligible) }
  let(:school_eligible_for_ecp_but_not_lup) { create(:school, :early_career_payments_eligible) }
  let(:school_ineligible_for_both_ecp_and_lup) { create(:school, :early_career_payments_ineligible) }

  before { create(:journey_configuration, :additional_payments, current_academic_year: academic_year) }

  # sanity check of factories
  specify { expect(Policies::EarlyCareerPayments::SchoolEligibility.new(school_eligible_for_ecp_but_not_lup)).to be_eligible }
  specify { expect(Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school_eligible_for_ecp_but_not_lup)).not_to be_eligible }

  specify { expect(Policies::EarlyCareerPayments::SchoolEligibility.new(school_ineligible_for_both_ecp_and_lup)).not_to be_eligible }
  specify { expect(Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school_ineligible_for_both_ecp_and_lup)).not_to be_eligible }

  let(:journey_session) do
    create(:additional_payments_session, answers: answers)
  end

  let(:checker) { described_class.new(journey_session.answers) }

  describe "#reason" do
    subject { checker.reason }

    context "school ineligible for both ECP and LUP" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          current_school_id: school_ineligible_for_both_ecp_and_lup.id
        )
      end

      it { is_expected.to eq(:current_school) }
    end

    context "short-term supply teacher" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :short_term_supply_teacher
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "agency supply teacher" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :agency_supply_teacher
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "short-term agency supply teacher" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :agency_supply_teacher,
          :short_term_supply_teacher
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "formal action" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          subject_to_formal_performance_action: true
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "disciplinary action" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          subject_to_disciplinary_action: true
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "formal and disciplinary action" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          subject_to_disciplinary_action: true,
          subject_to_formal_performance_action: true
        )
      end

      it { is_expected.to eq(:generic) }
    end

    context "eligible for both ECP and LUP but 'None of the above' ITT year" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          current_school_id: school_eligible_for_ecp_and_lup.id,
          itt_academic_year: none_of_the_above_academic_year
        )
      end

      it { is_expected.to eq(:teacher_with_ineligible_itt_year) }
    end

    context "eligible for ECP only but 'None of the above' ITT year" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible,
          itt_academic_year: none_of_the_above_academic_year
        )
      end

      it { is_expected.to eq(:ecp_only_teacher_with_ineligible_itt_year) }
    end

    context "eligible for LUP only but insufficient teaching" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :lup_eligible,
          :insufficient_teaching
        )
      end

      it { is_expected.to eq(:would_be_eligible_for_lup_only_except_for_insufficient_teaching) }
    end

    context "eligible for ECP only but insufficient teaching" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible,
          :first_lup_claim_year,
          :insufficient_teaching
        )
      end

      it { is_expected.to eq(:would_be_eligible_for_ecp_only_except_for_insufficient_teaching) }
    end

    context "eligible for both ECP and LUP except for insufficient teaching" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :insufficient_teaching
        )
      end

      it { is_expected.to eq(:would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching) }
    end

    context "bad ITT subject and no degree" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :no_relevant_degree,
          eligible_itt_subject: :none_of_the_above
        )
      end

      it { is_expected.to eq(:lack_both_valid_itt_subject_and_degree) }
    end

    context "non-LUP school, only given one ITT subject option but does not take the ECP subject option for 2018" do
      # This spec might need to change for future policy years
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          itt_academic_year: itt_year,
          current_school_id: school_eligible_for_ecp_but_not_lup.id,
          eligible_itt_subject: :none_of_the_above
        )
      end

      it { is_expected.to eq(:bad_itt_year_for_ecp) }
    end

    context "non-LUP school, given multiple ITT subject options but chose 'none of the above'" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          itt_academic_year: itt_year,
          current_school_id: school_eligible_for_ecp_but_not_lup.id,
          eligible_itt_subject: :none_of_the_above
        )
      end

      it { is_expected.to eq(:bad_itt_subject_for_ecp) }
    end

    context "trainee teacher at an ECP-only school" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :trainee_teacher,
          current_school_id: school_eligible_for_ecp_but_not_lup.id
        )
      end

      it { is_expected.to eq(:ecp_only_trainee_teacher) }
    end

    context "trainee teacher in an LUP school who isn't training to teach an eligible subject nor has a relevant degree" do
      let(:school) { build(:school, :levelling_up_premium_payments_eligible) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :trainee_teacher,
          :no_relevant_degree,
          eligible_itt_subject: :foreign_languages,
          current_school_id: school.id
        )
      end

      it { is_expected.to eq(:trainee_teaching_lacking_both_valid_itt_subject_and_degree) }
    end

    context "non-LUP school and no ECP subjects for ITT year" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :trainee_teacher,
          itt_academic_year: itt_year,
          current_school_id: school_eligible_for_ecp_but_not_lup.id,
          nqt_in_academic_year_after_itt: true
        )
      end

      it { is_expected.to eq(:no_ecp_subjects_that_itt_year) }
    end

    context "trainee teacher in last policy year" do
      let(:school) { build(:school, :combined_journey_eligibile_for_all) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :trainee_teacher,
          academic_year: AcademicYear.new(2025),
          current_school_id: school.id
        )
      end

      it { is_expected.to eq(:trainee_in_last_policy_year) }
    end

    context "when DQT-derived qualifications data indicates the user is ineligible" do
      let(:qualifications_details_check) { true }
      let(:logged_in_with_tid) { true }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :no_relevant_degree,
          eligible_itt_subject: :none_of_the_above,
          logged_in_with_tid: logged_in_with_tid,
          qualifications_details_check: qualifications_details_check
        )
      end

      it { is_expected.to eq(:dqt_data_ineligible) }
    end
  end
end

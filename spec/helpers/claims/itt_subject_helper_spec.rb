require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  before { create(:journey_configuration, :additional_payments) }

  let(:ecp_trainee_teacher_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
  let(:lup_trainee_teacher_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

  let(:ecp_trainee_teacher_claim) { create(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_trainee_teacher_eligibility) }
  let(:lup_trainee_teacher_claim) { create(:claim, :first_lup_claim_year, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_trainee_teacher_eligibility) }

  # FIXME RL remove this
  xdescribe "#subject_symbols" do
    let(:shim) do
      Journeys::AdditionalPaymentsForTeaching::ClaimJourneySessionShim.new(
        current_claim: CurrentClaim.new(claims: [build(:claim)]),
        journey_session: journey_session
      )
    end

    subject { helper.subject_symbols(shim.answers) }

    context "trainee teacher" do
      let(:journey_session) do
        create(
          :additional_payments_session,
          answers: attributes_for(
            :additional_payments_answers,
            :ecp_and_lup_eligible,
            :trainee_teacher
          )
        )
      end

      it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
    end

    # this delegates to another class which checks more combinations
    context "non-trainee example" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

      let(:journey_session) do
        create(
          :additional_payments_session,
          answers: attributes_for(
            :additional_payments_answers,
            :ecp_and_lup_eligible,
            itt_academic_year: itt_year
          )
        )
      end

      it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
    end
  end

  describe "#subjects_to_sentence_for_hint_text" do
    let(:ecp_claim) { create(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, :first_lup_claim_year, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }
    let(:journey_session) do
      create(:additional_payments_session, answers: answers)
    end

    let(:shimmed_answers) do
      Journeys::AdditionalPaymentsForTeaching::ClaimJourneySessionShim.new(
        current_claim: CurrentClaim.new(claims: [ecp_claim, lup_claim]),
        journey_session: journey_session
      ).answers
    end

    subject { helper.subjects_to_sentence_for_hint_text(shimmed_answers) }

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :trainee_teacher
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_ineligible,
          :lup_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for LUP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :lup_ineligible,
          :ecp_undetermined
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end

    context "ineligible for neither LUP nor ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, languages, mathematics or physics") }
    end

    context "LUP eligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible_later,
          :lup_eligible
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "LUP ineligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :lup_ineligible,
          :ecp_eligible_later
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end
  end
end

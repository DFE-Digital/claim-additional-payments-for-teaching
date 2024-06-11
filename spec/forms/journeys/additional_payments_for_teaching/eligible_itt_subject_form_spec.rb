require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibleIttSubjectForm, type: :model do
  before do
    create(
      :journey_configuration,
      :additional_payments,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:answers) do
    build(
      :additional_payments_answers,
      attributes_for(
        :additional_payments_answers,
        trainee_teacher,
        itt_academic_year: itt_academic_year
      )
    )
  end

  let(:journey_session) do
    create(:additional_payments_session, answers: answers)
  end

  let(:trainee_teacher) { nil }

  let(:itt_academic_year) { AcademicYear.new(2020) }

  let(:ecp_trainee_teacher_eligibility) do
    create(
      :early_career_payments_eligibility,
      :trainee_teacher
    )
  end

  let(:ecp_trainee_teacher_claim) do
    create(
      :claim,
      :first_lup_claim_year,
      policy: Policies::EarlyCareerPayments,
      eligibility: ecp_trainee_teacher_eligibility
    )
  end

  let(:ecp_qualified_teacher_eligibility) do
    create(
      :early_career_payments_eligibility,
      :eligible_now,
      :sufficient_teaching
    )
  end

  let(:ecp_qualified_teacher_claim) do
    create(
      :claim,
      policy: Policies::EarlyCareerPayments,
      eligibility: ecp_qualified_teacher_eligibility
    )
  end

  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      claim: current_claim,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    let(:claim) { ecp_qualified_teacher_claim }
    let(:params) { ActionController::Parameters.new }

    it do
      is_expected.to validate_inclusion_of(:eligible_itt_subject)
        .in_array(form.available_options)
        .with_message("Select a subject")
    end
  end

  describe "#available_subjects" do
    subject(:available_subjects) { form.available_subjects }

    let(:params) { ActionController::Parameters.new }

    context "when qualified teacher" do
      let(:claim) { ecp_qualified_teacher_claim }

      it do
        is_expected.to contain_exactly(
          "chemistry",
          "foreign_languages",
          "mathematics",
          "physics"
        )
      end
    end

    context "when trainee teacher" do
      context "when in ECP and LUP policy year range" do
        let(:claim) { ecp_trainee_teacher_claim }
        let(:trainee_teacher) { :trainee_teacher }

        it do
          is_expected.to contain_exactly(
            "chemistry",
            "computing",
            "mathematics",
            "physics"
          )
        end
      end
    end
  end

  describe "#show_hint_text?" do
    subject { form.show_hint_text? }

    let(:params) { ActionController::Parameters.new }

    context "when the claim is for a trainee teacher" do
      let(:claim) { ecp_trainee_teacher_claim }

      it { is_expected.to be false }
    end

    context "when the claim is for a qualified teacher" do
      let(:claim) { ecp_qualified_teacher_claim }

      context "when there is a single avaialble subject" do
        let(:itt_academic_year) { AcademicYear.new(2018) }

        before do
          Journeys::Configuration.last.update!(
            current_academic_year: AcademicYear.new(2019)
          )
        end

        it { is_expected.to be false }
      end

      context "when there are multiple available subjects" do
        it { is_expected.to be true }
      end
    end
  end

  describe "#chemistry_or_physics_available?" do
    subject { form.chemistry_or_physics_available? }

    let(:params) { ActionController::Parameters.new }

    let(:claim) { ecp_trainee_teacher_claim }
    let(:trainee_teacher) { :trainee_teacher }

    context "when the subject list contains chemistry" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:chemistry])
        )
      end

      it { is_expected.to be true }
    end

    context "when the subject list contains physics" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:physics])
        )
      end

      it { is_expected.to be true }
    end

    context "when the subject list does not contain chemistry or physics" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:mathematics])
        )
      end

      it { is_expected.to be false }
    end
  end

  describe "#save" do
    let(:claim) { ecp_qualified_teacher_claim }

    context "when invalid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "invalid"
          }
        )
      end

      it "returns false" do
        expect(form.save).to be(false)
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "chemistry"
          }
        )
      end

      it "returns true and updates the claim's eligibility" do
        expect { expect(form.save).to be true }.to(
          change { claim.eligibility.eligible_itt_subject }
          .from("mathematics")
          .to("chemistry")
        )
      end

      it "resets dependent attributes" do
        expect { form.save }.to(
          change { claim.eligibility.teaching_subject_now }
          .from(true)
          .to(nil)
        )
      end
    end
  end
end

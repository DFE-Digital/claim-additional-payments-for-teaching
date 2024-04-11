require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibleIttSubjectForm, type: :model do
  before do
    create(
      :journey_configuration,
      :additional_payments,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  let(:additional_payments_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:ecp_trainee_teacher_eligibility) do
    create(
      :early_career_payments_eligibility,
      :trainee_teacher,
      itt_academic_year: AcademicYear.new(2020)
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
      :sufficient_teaching,
      itt_academic_year: AcademicYear.new(2020)
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

  describe "validations" do
    let(:claim) { ecp_qualified_teacher_claim }

    subject(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: ActionController::Parameters.new
      )
    end

    it do
      is_expected.to validate_inclusion_of(:eligible_itt_subject)
        .in_array(form.available_options)
        .with_message("Select a subject")
    end
  end

  describe "#save" do
    let(:claim) { ecp_qualified_teacher_claim }

    let(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: params
      )
    end

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

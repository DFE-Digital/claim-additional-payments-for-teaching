require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyClaimForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:eligibility) { create(:further_education_payments_eligibility) }

  let(:claim) { eligibility.claim }

  let(:journey_session) do
    create(
      :further_education_payments_provider_session,
      answers: {
        claim_id: claim.id,
        dfe_sign_in_uid: "123"
      }
    )
  end

  let(:params) { ActionController::Parameters.new }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.to validate_acceptance_of(:declaration)
    end

    it "validates all assertions are answered" do
      form.validate

      form.assertions.each do |assertion|
        expect(assertion.errors[:outcome]).to eq(["Select an option"])
      end
    end
  end

  describe "#assertions" do
    subject { form.assertions.map(&:name) }

    context "with a fixed term contract" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          contract_type: "permanent"
        )
      end

      it do
        is_expected.to eq(
          %w[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            teaching_hours_per_week
            hours_teaching_eligible_subjects
            subjects_taught
          ]
        )
      end
    end

    context "with a variable hours contract" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          contract_type: "variable_hours"
        )
      end

      it do
        is_expected.to eq(
          %w[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            taught_at_least_one_term
            teaching_hours_per_week
            hours_teaching_eligible_subjects
            subjects_taught
            teaching_hours_per_week_next_term
          ]
        )
      end
    end
  end
end

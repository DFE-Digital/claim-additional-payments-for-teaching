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
        dfe_sign_in_uid: "123",
        dfe_sign_in_first_name: "Seymoure",
        dfe_sign_in_last_name: "Skinner",
        dfe_sign_in_email: "seymore.skinner@springfield-elementary.edu"
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

  describe "#save" do
    let(:params) do
      ActionController::Parameters.new(
        {
          claim: {
            declaration: "1",
            assertions_attributes: {
              "0": {name: "contract_type", outcome: "1"},
              "1": {name: "teaching_responsibilities", outcome: "1"},
              "2": {name: "further_education_teaching_start_year", outcome: "1"},
              "3": {name: "teaching_hours_per_week", outcome: "1"},
              "4": {name: "hours_teaching_eligible_subjects", outcome: "0"},
              "5": {name: "subjects_taught", outcome: "0"}
            }
          }
        }
      )
    end

    it "verifies the claim" do
      travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
        form.save
      end

      expect(claim.reload.eligibility.verification).to match(
        {
          "assertions" => [
            {
              "name" => "contract_type",
              "outcome" => true
            },
            {
              "name" => "teaching_responsibilities",
              "outcome" => true
            },
            {
              "name" => "further_education_teaching_start_year",
              "outcome" => true
            },
            {
              "name" => "teaching_hours_per_week",
              "outcome" => true
            },
            {
              "name" => "hours_teaching_eligible_subjects",
              "outcome" => false
            },
            {
              "name" => "subjects_taught",
              "outcome" => false
            }
          ],
          "verifier" => {
            "dfe_sign_in_uid" => "123",
            "first_name" => "Seymoure",
            "last_name" => "Skinner",
            "email" => "seymore.skinner@springfield-elementary.edu"
          },
          "created_at" => "2024-01-01T12:00:00.000+00:00"
        }
      )
    end
  end
end

require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyClaimForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:school) do
    create(:school, :further_education, name: "Springfield Elementary")
  end

  let(:eligibility) do
    create(
      :further_education_payments_eligibility,
      school: school
    )
  end

  let(:claim) do
    create(
      :claim,
      eligibility: eligibility,
      policy: Policies::FurtherEducationPayments,
      first_name: "Edna",
      surname: "Krabappel"
    )
  end

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
      is_expected.to(
        validate_acceptance_of(:declaration).with_message(
          "Tick the box to confirm that the information provided in this form is correct to the best of your knowledge"
        )
      )
    end

    it "validates the claim hasn't already been verified" do
      eligibility.update!(
        verification: {
          assertions: [
            {name: "contract_type", outcome: true}
          ]
        }
      )

      form.validate

      expect(form.errors[:base]).to eq(["Claim has already been verified"])
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

  describe "AssertionForm" do
    let(:contract_type) { "fixed_contract" }

    subject do
      described_class::AssertionForm.new(
        name: assertion_name,
        type: contract_type,
        claim: claim
      )
    end

    context "when the assertion is `contract_type`" do
      let(:assertion_name) { "contract_type" }

      context "when fixed term" do
        let(:contract_type) { "fixed_contract" }

        it do
          is_expected.not_to(allow_value(nil).for(:outcome).with_message(
            "Select yes if Edna has a fixed term contract of employment at Springfield Elementary"
          ))
        end
      end

      context "when variable" do
        let(:contract_type) { "variable_contract" }

        it do
          is_expected.not_to(allow_value(nil).for(:outcome).with_message(
            "Select yes if Edna has a variable hours contract of employment at Springfield Elementary"
          ))
        end
      end
    end

    context "when the assertion is `teaching_responsibilities`" do
      let(:assertion_name) { "teaching_responsibilities" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna is a member of staff with teaching responsibilities"
        ))
      end
    end

    context "when the assertion is `further_education_teaching_start_year`" do
      let(:assertion_name) { "further_education_teaching_start_year" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna is in the first 5 years of their further education teaching career in England"
        ))
      end
    end

    context "when the assertion is `taught_at_least_one_term`" do
      let(:assertion_name) { "taught_at_least_one_term" }

      let(:contract_type) { "variable_contract" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna has taught at least one academic term at Springfield Elementary"
        ))
      end
    end

    context "when the assertion is `teaching_hours_per_week`" do
      let(:assertion_name) { "teaching_hours_per_week" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna is timetabled to teach an average of 12 hours per week during the current term"
        ))
      end
    end

    context "when the assertion is `hours_teaching_eligible_subjects`" do
      let(:assertion_name) { "hours_teaching_eligible_subjects" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna teaches 16- to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP), for at least half of their timetabled teaching hours"
        ))
      end
    end

    context "when the assertion is `subjects_taught`" do
      let(:assertion_name) { "subjects_taught" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna teaches this course for at least half their timetabled teaching hours"
        ))
      end
    end

    context "when the assertion is `teaching_hours_per_week_next_term`" do
      let(:assertion_name) { "teaching_hours_per_week_next_term" }

      let(:contract_type) { "variable_contract" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna will be timetabled to teach at least 2.5 hours per week next term"
        ))
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

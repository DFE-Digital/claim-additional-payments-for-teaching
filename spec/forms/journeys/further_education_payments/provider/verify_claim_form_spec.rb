require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyClaimForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:school) do
    create(
      :school,
      :further_education,
      :fe_eligible,
      name: "Springfield Elementary"
    )
  end

  let(:teaching_hours_per_week) { "more_than_12" }

  let(:contract_type) { "fixed_term" }

  let(:eligibility) do
    create(
      :further_education_payments_eligibility,
      school: school,
      teaching_hours_per_week: teaching_hours_per_week,
      contract_type: contract_type,
      fixed_term_full_year: true
    )
  end

  let(:claim) do
    create(
      :claim,
      eligibility: eligibility,
      policy: Policies::FurtherEducationPayments,
      first_name: "Edna",
      surname: "Krabappel",
      reference: "ABC123"
    )
  end

  let(:journey_session) do
    create(
      :further_education_payments_provider_session,
      answers: {
        claim_id: claim.id,
        dfe_sign_in_uid: "123",
        dfe_sign_in_first_name: "Seymour",
        dfe_sign_in_last_name: "Skinner",
        dfe_sign_in_email: "seymour.skinner@springfield-elementary.edu",
        dfe_sign_in_organisation_name: "Springfield Elementary",
        dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
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

    context "when claim identity verification is required" do
      before do
        claim.update!(
          onelogin_idv_at: DateTime.now,
          identity_confirmed_with_onelogin: false
        )
      end

      it do
        is_expected.not_to(validate_acceptance_of(:declaration))
      end
    end

    context "when claim identity verification is not required" do
      it do
        is_expected.to(
          validate_acceptance_of(:declaration).with_message(
            "Tick the box to confirm that the information provided in this " \
            "form is correct to the best of your knowledge"
          )
        )
      end
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
            half_teaching_hours
            subjects_taught
            subject_to_formal_performance_action
            subject_to_disciplinary_action
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
            half_teaching_hours
            subjects_taught
            teaching_hours_per_week_next_term
            subject_to_formal_performance_action
            subject_to_disciplinary_action
          ]
        )
      end
    end
  end

  describe "AssertionForm" do
    subject do
      described_class::AssertionForm.new(
        name: assertion_name,
        parent_form: form
      )
    end

    context "when the assertion is `contract_type`" do
      let(:assertion_name) { "contract_type" }

      context "when fixed term" do
        it do
          is_expected.not_to(allow_value(nil).for(:outcome).with_message(
            "Select yes if Edna has a fixed term contract of employment at Springfield Elementary"
          ))
        end
      end

      context "when variable" do
        let(:contract_type) { "variable_hours" }

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

      let(:contract_type) { "variable_hours" }

      it do
        is_expected.not_to(allow_value(nil).for(:outcome).with_message(
          "Select yes if Edna has taught at least one academic term at Springfield Elementary"
        ))
      end
    end

    context "when the assertion is `teaching_hours_per_week`" do
      let(:assertion_name) { "teaching_hours_per_week" }

      context "when more that 12" do
        it do
          is_expected.not_to(allow_value(nil).for(:outcome).with_message(
            "Select yes if Edna is timetabled to teach an average of 12 hours or more per week during the current term"
          ))
        end
      end

      context "when between 2.5 and 12" do
        let(:teaching_hours_per_week) { "between_2_5_and_12" }

        it do
          is_expected.not_to(allow_value(nil).for(:outcome).with_message(
            "Select yes if Edna is timetabled to teach an average of 2.5 hours or more but less than 12 hours per week during the current term"
          ))
        end
      end
    end

    context "when the assertion is `half_teaching_hours`" do
      let(:assertion_name) { "half_teaching_hours" }

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

      let(:contract_type) { "variable_hours" }

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
              "4": {name: "half_teaching_hours", outcome: "0"},
              "5": {name: "subjects_taught", outcome: "0"},
              "6": {name: "subject_to_formal_performance_action", outcome: "0"},
              "7": {name: "subject_to_disciplinary_action", outcome: "0"}
            }
          }
        }
      )
    end

    around do |example|
      travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
        perform_enqueued_jobs do
          example.run
        end
      end
    end

    context "when identity verification is required" do
      before do
        claim.update!(
          onelogin_idv_at: Time.zone.now,
          identity_confirmed_with_onelogin: false
        )

        form.save
      end

      it "doesn't updated the claim" do
        expect(claim.reload.eligibility.verification).to be_empty
      end

      it "doesn't create a provider verification task" do
        expect(
          claim.reload.tasks.where(name: "provider_verification")
        ).not_to be_present
      end

      it "doesn't send a confirmation email" do
        expect(
          claim.school.eligible_fe_provider.primary_key_contact_email_address
        ).not_to have_received_email(
          "70942fe1-5838-4d37-904c-9d070f2582f0"
        )
      end
    end

    context "when identity verification is not required" do
      before do
        dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
        dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
        allow(Dqt::Client).to receive(:new).and_return(dqt_client)

        form.save
      end

      it "verifies the claim" do
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
                "name" => "half_teaching_hours",
                "outcome" => false
              },
              {
                "name" => "subjects_taught",
                "outcome" => false
              },
              {
                "name" => "subject_to_formal_performance_action",
                "outcome" => false
              },
              {
                "name" => "subject_to_disciplinary_action",
                "outcome" => false
              }
            ],
            "verifier" => {
              "dfe_sign_in_uid" => "123",
              "first_name" => "Seymour",
              "last_name" => "Skinner",
              "email" => "seymour.skinner@springfield-elementary.edu",
              "dfe_sign_in_organisation_name" => "Springfield Elementary",
              "dfe_sign_in_role_codes" => ["teacher_payments_claim_verifier"]
            },
            "created_at" => "2024-01-01T12:00:00.000+00:00"
          }
        )

        expect(claim.verified_at).to eq(DateTime.new(2024, 1, 1, 12, 0, 0))
      end

      it "creates a provider verification task" do
        task = claim.reload.tasks.find_by(name: "provider_verification")

        expect(task.created_by.email).to eq(
          "seymour.skinner@springfield-elementary.edu"
        )
      end

      it "sends the provider a confirmation email" do
        expect(
          claim.school.eligible_fe_provider.primary_key_contact_email_address
        ).to have_received_email(
          "70942fe1-5838-4d37-904c-9d070f2582f0",
          recipient_name: "Springfield Elementary",
          claim_reference: "ABC123",
          claimant_name: "Edna Krabappel",
          verifier_name: "Seymour Skinner",
          verification_date: "1 January 2024"
        )
      end
    end
  end

  describe "initialize" do
    context "with a existing verified session" do
      before do
        journey_session.answers.assign_attributes(
          verification: {
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
                "name" => "half_teaching_hours",
                "outcome" => false
              },
              {
                "name" => "subjects_taught",
                "outcome" => false
              },
              {
                "name" => "subject_to_formal_performance_action",
                "outcome" => false
              },
              {
                "name" => "subject_to_disciplinary_action",
                "outcome" => false
              }
            ],
            "verifier" => {
              "dfe_sign_in_uid" => "123",
              "first_name" => "Seymour",
              "last_name" => "Skinner",
              "email" => "seymour.skinner@springfield-elementary.edu",
              "dfe_sign_in_organisation_name" => "Springfield Elementary",
              "dfe_sign_in_role_codes" => ["teacher_payments_claim_verifier"]
            },
            "created_at" => "2024-01-01T12:00:00.000+00:00"
          }
        )

        journey_session.save!
      end

      it "sets the attributes on the form" do
        expect(form.assertions.map(&:attributes)).to eq(
          [
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
              "name" => "half_teaching_hours",
              "outcome" => false
            },
            {
              "name" => "subjects_taught",
              "outcome" => false
            },
            {
              "name" => "subject_to_formal_performance_action",
              "outcome" => false
            },
            {
              "name" => "subject_to_disciplinary_action",
              "outcome" => false
            }
          ]
        )
      end

      it "creates a valid form" do
        expect(form).to be_valid
      end
    end
  end
end

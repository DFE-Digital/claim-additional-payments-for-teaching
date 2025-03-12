require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyIdentityForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:school) do
    create(
      :school,
      :further_education,
      :fe_eligible,
      name: "Springfield Elementary"
    )
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
        dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"],
        verification: {
          assertions: [
            {
              name: "contract_type",
              outcome: true
            },
            {
              name: "teaching_responsibilities",
              outcome: true
            },
            {
              name: "further_education_teaching_start_year",
              outcome: true
            },
            {
              name: "teaching_hours_per_week",
              outcome: true
            },
            {
              name: "half_teaching_hours",
              outcome: false
            },
            {
              name: "subjects_taught",
              outcome: false
            },
            {
              name: "subject_to_formal_performance_action",
              outcome: false
            },
            {
              name: "subject_to_disciplinary_action",
              outcome: false
            }
          ],
          verifier: {
            dfe_sign_in_uid: "123",
            first_name: "Seymour",
            last_name: "Skinner",
            email: "seymour.skinner@springfield-elementary.edu",
            dfe_sign_in_organisation_name: "Springfield Elementary",
            dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
          },
          created_at: "2024-01-01T12:00:00.000+00:00"
        }
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
        validate_presence_of(:claimant_date_of_birth)
          .with_message("Enter Edna’s date of birth")
      )
    end

    it do
      is_expected.to(
        validate_presence_of(:claimant_postcode)
          .with_message("Enter Edna’s postcode")
      )
    end

    it do
      is_expected.not_to(
        allow_value("SW1A").for(:claimant_postcode)
          .with_message("Enter a postcode in the correct format")
      )
    end

    it do
      is_expected.to(
        validate_presence_of(:claimant_national_insurance_number)
          .with_message("Enter Edna’s National Insurance number")
      )
    end

    it do
      is_expected.not_to(
        allow_value("QQ123456").for(:claimant_national_insurance_number)
          .with_message("Enter a National Insurance number in the correct format")
      )
    end

    it do
      is_expected.not_to(
        allow_value(nil).for(:claimant_valid_passport)
          .with_message("Select yes if Edna has a valid passport")
      )
    end

    it do
      is_expected.to(
        validate_acceptance_of(:declaration).with_message(
          "Tick the box to confirm that you have verified the claimant’s " \
          "identity and the information provided in this form is correct"
        )
      )
    end

    context "when claimant_valid_passport is true" do
      before do
        form.claimant_valid_passport = true
      end

      it do
        is_expected.to(
          validate_presence_of(:claimant_passport_number)
            .with_message("Enter Edna’s passport number")
        )
      end
    end

    context "when claimant_valid_passport is false" do
      before do
        form.claimant_valid_passport = false
      end

      it { is_expected.not_to validate_presence_of(:claimant_passport_number) }
    end
  end

  describe "#claimant_first_name" do
    it "returns the claimant's first name" do
      expect(form.claimant_first_name).to eq("Edna")
    end
  end

  describe "#save" do
    let(:params) do
      ActionController::Parameters.new(
        {
          claim: {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "1949",
            claimant_postcode: "SW1A 1AA",
            claimant_national_insurance_number: "QQ123456C",
            claimant_valid_passport: "true",
            claimant_passport_number: "123456789",
            declaration: "1"
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

    before do
      dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
      dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
      allow(Dqt::Client).to receive(:new).and_return(dqt_client)

      # Sanity check
      expect(form.save).to be(true)
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

    it "verifies the claimant's identity" do
      eligibility = claim.reload.eligibility

      expect(eligibility.claimant_date_of_birth).to eq(Date.new(1949, 1, 21))

      expect(eligibility.claimant_postcode).to eq("SW1A 1AA")

      expect(eligibility.claimant_national_insurance_number).to eq("QQ123456C")

      expect(eligibility.claimant_valid_passport).to eq(true)

      expect(eligibility.claimant_passport_number).to eq("123456789")

      expect(eligibility.claimant_identity_verified_at).to eq(
        DateTime.new(2024, 1, 1, 12, 0, 0)
      )
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

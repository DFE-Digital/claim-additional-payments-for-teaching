require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FeAlternativeVerification do
  describe "#perform" do
    context "when personal details and bank details match" do
      it "creates a passed task" do
        claim = create(
          :claim,
          :further_education,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "te57 1ng",
          national_insurance_number: "AB123456C",
          banking_name: "Test User",
          first_name: "Test",
          surname: "User",
          hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "yes"}}],
          eligibility_attributes: {
            provider_verification_claimant_employed_by_college: true,
            provider_verification_claimant_date_of_birth: Date.new(1970, 1, 1),
            provider_verification_claimant_postcode: "TE57 1NG",
            provider_verification_claimant_national_insurance_number: "AB123456C",
            provider_verification_claimant_email: "test@example.com",
            work_email: "test@example.com"
          }
        )

        described_class.new(claim: claim).perform

        task = claim.tasks.find_by!(name: "fe_alternative_verification")

        expect(task.passed).to be true
        expect(task.manual).to be false
        expect(task.data).to eq(
          "personal_details_task_completed_automatically" => true,
          "personal_details_match" => true,
          "bank_details_task_completed_automatically" => true,
          "bank_details_match" => true
        )
      end
    end

    context "when only personal details match" do
      context "when bank details don't match" do
        it "leaves the decision to ops" do
          claim = create(
            :claim,
            :further_education,
            date_of_birth: Date.new(1970, 1, 1),
            postcode: "te57 1ng",
            national_insurance_number: "AB123456C",
            banking_name: "Test User",
            first_name: "Test",
            surname: "User",
            hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "no"}}],
            eligibility_attributes: {
              provider_verification_claimant_employed_by_college: true,
              provider_verification_claimant_date_of_birth: Date.new(1970, 1, 1),
              provider_verification_claimant_postcode: "TE57 1NG",
              provider_verification_claimant_national_insurance_number: "AB123456C",
              provider_verification_claimant_email: "test@example.com",
              work_email: "test@example.com"
            }
          )

          described_class.new(claim: claim).perform

          task = claim.tasks.find_by!(name: "fe_alternative_verification")

          expect(task.passed).to be_nil
          expect(task.manual).to be_nil
          expect(task.data).to eq(
            "personal_details_task_completed_automatically" => true,
            "personal_details_match" => true
          )
        end
      end

      context "when bank details are failable" do
        it "creates a failed task" do
          claim = create(
            :claim,
            :further_education,
            date_of_birth: Date.new(1970, 1, 1),
            postcode: "te57 1ng",
            national_insurance_number: "AB123456C",
            banking_name: "Test User",
            first_name: "Test",
            surname: "User",
            hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "yes"}}],
            eligibility_attributes: {
              provider_verification_claimant_employed_by_college: true,
              provider_verification_claimant_date_of_birth: Date.new(1970, 1, 1),
              provider_verification_claimant_postcode: "TE57 1NG",
              provider_verification_claimant_national_insurance_number: "AB123456C",
              provider_verification_claimant_email: "test@example.com",
              work_email: "test@example.com",
              provider_verification_claimant_bank_details_match: false
            }
          )

          described_class.new(claim: claim).perform

          task = claim.tasks.find_by!(name: "fe_alternative_verification")

          expect(task.passed).to be false
          expect(task.manual).to be false
          expect(task.data).to eq(
            "personal_details_task_completed_automatically" => true,
            "personal_details_match" => true,
            "bank_details_task_completed_automatically" => true,
            "bank_details_match" => false
          )
        end
      end
    end

    context "when only bank details match" do
      context "when personal details don't match" do
        it "leaves the decision to ops" do
          claim = create(
            :claim,
            :further_education,
            date_of_birth: Date.new(1980, 1, 1),
            postcode: "te57 1ng",
            national_insurance_number: "AB123456C",
            banking_name: "Test User",
            first_name: "Test",
            surname: "User",
            hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "yes"}}],
            eligibility_attributes: {
              provider_verification_claimant_employed_by_college: true,
              provider_verification_claimant_date_of_birth: Date.new(1970, 1, 1),
              provider_verification_claimant_postcode: "TE57 1NG",
              provider_verification_claimant_national_insurance_number: "AB123456C",
              provider_verification_claimant_email: "test@example.com",
              work_email: "test@example.com"
            }
          )

          described_class.new(claim: claim).perform

          task = claim.tasks.find_by!(name: "fe_alternative_verification")

          expect(task.passed).to be_nil
          expect(task.manual).to be_nil
          expect(task.data).to eq(
            "bank_details_task_completed_automatically" => true,
            "bank_details_match" => true
          )
        end
      end

      context "when personal details are failable" do
        it "creates a failed task" do
          claim = create(
            :claim,
            :further_education,
            date_of_birth: Date.new(1970, 1, 1),
            postcode: "te57 1ng",
            national_insurance_number: "AB123456C",
            banking_name: "Test User",
            first_name: "Test",
            surname: "User",
            hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "yes"}}],
            eligibility_attributes: {
              provider_verification_claimant_employed_by_college: false
            }
          )

          described_class.new(claim: claim).perform

          task = claim.tasks.find_by!(name: "fe_alternative_verification")

          expect(task.passed).to be false
          expect(task.manual).to be false
          expect(task.data).to eq(
            "personal_details_task_completed_automatically" => true,
            "personal_details_match" => false
          )
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification do
  describe "#perform" do
    context "when the claimant's identity has not been verified" do
      it "doesn't create a task" do
        claim = create(
          :further_education_payments_eligibility,
          claimant_identity_verified_at: nil
        ).claim

        expect { described_class.new(claim: claim).perform }.not_to(
          change { claim.tasks.count }
        )
      end
    end

    context "when the claimant's identity has been verified" do
      context "when the task has already been performed" do
        it "doesn't create a new task" do
          claim = create(
            :further_education_payments_eligibility,
            claimant_identity_verified_at: DateTime.now
          ).claim

          create(
            :task,
            name: "alternative_identity_verification",
            claim: claim
          )

          expect { described_class.new(claim: claim).perform }.not_to(
            change { claim.tasks.count }
          )
        end
      end

      context "when the task has not been performed" do
        context "when the provider and claimant details match" do
          it "passes the task" do
            eligibility = create(
              :further_education_payments_eligibility,
              claimant_identity_verified_at: DateTime.now,
              claimant_date_of_birth: Date.new(1990, 1, 1),
              claimant_postcode: "TE57 1NG",
              claimant_national_insurance_number: "QQ123456C",
              claimant_valid_passport: false,
              claimant_passport_number: nil,
              valid_passport: false,
              passport_number: nil,
              verification: {
                verifier: {
                  dfe_sign_in_uid: "123",
                  first_name: "Seymour",
                  last_name: "Skinner",
                  email: "seymore.skinner@springfield-elementary.edu",
                  dfe_sign_in_organisation_name: "Springfield Elementary",
                  dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                }
              }
            )

            claim = create(
              :claim,
              eligibility: eligibility,
              policy: eligibility.policy,
              postcode: "te571ng",
              national_insurance_number: "qq123456c",
              date_of_birth: Date.new(1990, 1, 1)
            )

            expect { described_class.new(claim: claim).perform }.to(
              change(
                claim.tasks.where(name: "alternative_identity_verification"),
                :count
              ).from(0).to(1)
            )

            task = claim.tasks.find_by!(
              name: "alternative_identity_verification"
            )

            expect(task.passed).to eq(true)
            expect(task.manual).to eq(false)
            expect(task.created_by.email).to eq(
              "seymore.skinner@springfield-elementary.edu"
            )
          end
        end

        context "when the provider and claimant details do not match" do
          it "doesn't create the task" do
            eligibility = create(
              :further_education_payments_eligibility,
              claimant_identity_verified_at: DateTime.now,
              claimant_date_of_birth: Date.new(1990, 1, 1),
              claimant_postcode: "TE57 1NG",
              claimant_national_insurance_number: "QQ123456C",
              claimant_valid_passport: true,
              claimant_passport_number: "123456789",
              valid_passport: false,
              passport_number: nil,
              verification: {
                verifier: {
                  dfe_sign_in_uid: "123",
                  first_name: "Seymour",
                  last_name: "Skinner",
                  email: "seymore.skinner@springfield-elementary.edu",
                  dfe_sign_in_organisation_name: "Springfield Elementary",
                  dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                }
              }
            )

            claim = create(
              :claim,
              eligibility: eligibility,
              policy: eligibility.policy,
              postcode: "TE57 1NG",
              national_insurance_number: "QQ123456C",
              date_of_birth: Date.new(1990, 1, 1)
            )

            expect { described_class.new(claim: claim).perform }.not_to(
              change(
                claim.tasks.where(name: "alternative_identity_verification"),
                :count
              )
            )
          end
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::ProviderVerification do
  describe "#initialize" do
    context "with a non FE claim" do
      it "errors" do
        claim = create(:claim)

        expect { described_class.new(claim: claim) }.to(
          raise_error(ArgumentError, "Claim must be an Further Education claim")
        )
      end
    end
  end

  describe "#perform" do
    context "when the claim has not been verified by the provider" do
      let(:verification) { {} }

      it "doesn't create a task" do
        eligibility = create(
          :further_education_payments_eligibility,
          verification: verification
        )

        claim = create(
          :claim,
          :further_education,
          eligibility:
        )

        expect { described_class.new(claim: claim).perform }.not_to(
          change { claim.tasks.count }
        )
      end
    end

    context "when the claim has been verified by the provider" do
      context "when the task has already been performed" do
        it "does not alter the task or create a new one" do
          eligibility = create(
            :further_education_payments_eligibility
          )

          claim = create(
            :claim,
            :further_education,
            :verified,
            eligibility:
          )

          task = create(
            :task,
            name: "provider_verification",
            claim: claim,
            passed: true
          )

          expect { described_class.new(claim: claim).perform }.to(
            not_change { claim.tasks.count }.and(
              not_change { task.reload.updated_at }
            )
          )
        end
      end

      context "when the task has not been performed" do
        context "when the provider has not confirmed the claimants answers" do
          it "fails the task" do
            eligibility = create(
              :further_education_payments_eligibility,
              verification: {
                assertions: [
                  {name: "contract_type", outcome: false}
                ],
                verifier: {
                  dfe_sign_in_uid: "123",
                  first_name: "Seymour",
                  last_name: "Skinner",
                  email: "seymore.skinner@springfield-elementary.edu",
                  dfe_sign_in_organisation_name: "Springfield Elementary",
                  dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                },
                created_at: Time.zone.now
              }
            )

            claim = create(
              :claim,
              :further_education,
              eligibility:
            )

            expect { described_class.new(claim: claim).perform }.to(
              change { claim.tasks.count }.from(0).to(1).and(
                change(DfeSignIn::User, :count).from(0).to(1)
              )
            )

            task = claim.tasks.last

            expect(task.name).to eq("provider_verification")
            expect(task.passed).to eq(false)
            expect(task.manual).to eq(false)

            dfe_sign_in_user = task.created_by

            expect(dfe_sign_in_user.dfe_sign_in_id).to eq("123")
            expect(dfe_sign_in_user.given_name).to eq("Seymour")
            expect(dfe_sign_in_user.family_name).to eq("Skinner")
            expect(dfe_sign_in_user.email).to eq(
              "seymore.skinner@springfield-elementary.edu"
            )
            expect(dfe_sign_in_user.organisation_name).to eq(
              "Springfield Elementary"
            )
            expect(dfe_sign_in_user.role_codes).to eq(
              ["teacher_payments_claim_verifier"]
            )
          end
        end

        context "when the provider has confirmed the claimants answers" do
          it "passes the task" do
            eligibility = create(
              :further_education_payments_eligibility,
              verification: {
                assertions: [
                  {name: "contract_type", outcome: true}
                ],
                verifier: {
                  dfe_sign_in_uid: "123",
                  first_name: "Seymour",
                  last_name: "Skinner",
                  email: "seymore.skinner@springfield-elementary.edu",
                  dfe_sign_in_organisation_name: "Springfield Elementary",
                  dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                },
                created_at: Time.zone.now
              }
            )

            claim = create(
              :claim,
              :further_education,
              eligibility:
            )

            expect { described_class.new(claim: claim).perform }.to(
              change { claim.tasks.count }.from(0).to(1).and(
                change(DfeSignIn::User, :count).from(0).to(1)
              )
            )

            task = claim.tasks.last

            expect(task.name).to eq("provider_verification")
            expect(task.passed).to eq(true)
            expect(task.manual).to eq(false)

            dfe_sign_in_user = task.created_by

            expect(dfe_sign_in_user.dfe_sign_in_id).to eq("123")
            expect(dfe_sign_in_user.given_name).to eq("Seymour")
            expect(dfe_sign_in_user.family_name).to eq("Skinner")
            expect(dfe_sign_in_user.email).to eq(
              "seymore.skinner@springfield-elementary.edu"
            )
            expect(dfe_sign_in_user.organisation_name).to eq(
              "Springfield Elementary"
            )
            expect(dfe_sign_in_user.role_codes).to eq(
              ["teacher_payments_claim_verifier"]
            )
          end
        end

        context "when the verifier already exists" do
          it "does not create a new verifier" do
            dfe_sign_in_user = create(
              :dfe_signin_user,
              :provider,
              dfe_sign_in_id: "123"
            )

            eligibility = create(
              :further_education_payments_eligibility,
              verification: {
                assertions: [
                  {name: "contract_type", outcome: true}
                ],
                verifier: {
                  dfe_sign_in_uid: "123",
                  first_name: "Seymour",
                  last_name: "Skinner",
                  email: "seymore.skinner@springfield-elementary.edu",
                  dfe_sign_in_organisation_name: "Springfield Elementary",
                  dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                },
                created_at: Time.zone.now
              }
            )

            claim = create(
              :claim,
              :further_education,
              eligibility:
            )

            expect { described_class.new(claim: claim).perform }.to(
              change { claim.tasks.count }.from(0).to(1).and(
                not_change(DfeSignIn::User, :count)
              )
            )

            task = claim.tasks.last

            expect(task.name).to eq("provider_verification")
            expect(task.passed).to eq(true)
            expect(task.manual).to eq(false)

            expect(task.created_by).to eq(dfe_sign_in_user)
          end
        end
      end
    end
  end
end

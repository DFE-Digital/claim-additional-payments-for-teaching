require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::ProviderVerification do
  describe "#initialize" do
    context "with a non FE claim" do
      it "errors" do
        claim = create(:claim) # Default is student loans policy

        expect { described_class.new(claim:) }.to raise_error(
          ArgumentError,
          "Claim must be an Further Education claim"
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

            expect { described_class.new(claim:).perform }.to(
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
              contract_type: "permanent",
              teaching_hours_per_week: "more_than_12",
              provider_verification_contract_type: "permanent",
              provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
              provider_verification_teaching_qualification: "yes",
              provider_verification_performance_measures: false,
              provider_verification_disciplinary_action: false,
              verification: {
                assertions: [
                  {name: "teaching_responsibilities", outcome: true},
                  {name: "in_first_five_years", outcome: true},
                  {name: "half_teaching_hours", outcome: true},
                  {name: "subjects_taught", outcome: true},
                  {name: "taught_at_least_one_term", outcome: true}
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

            expect { described_class.new(claim:).perform }.to(
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
            expect(dfe_sign_in_user.organisation_name).to eq("Springfield Elementary")
            expect(dfe_sign_in_user.role_codes).to eq(["teacher_payments_claim_verifier"])
          end
        end

        context "when the verifier already exists" do
          it "does not create a new verifier" do
            user = create(
              :dfe_signin_user,
              dfe_sign_in_id: "123",
              user_type: "provider",
              given_name: "Seymour",
              family_name: "Skinner"
            )

            eligibility = create(
              :further_education_payments_eligibility,
              contract_type: "permanent",
              teaching_hours_per_week: "more_than_12",
              provider_verification_contract_type: "permanent",
              provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
              provider_verification_teaching_qualification: "yes",
              provider_verification_performance_measures: false,
              provider_verification_disciplinary_action: false,
              verification: {
                assertions: [
                  {name: "teaching_responsibilities", outcome: true},
                  {name: "in_first_five_years", outcome: true},
                  {name: "half_teaching_hours", outcome: true},
                  {name: "subjects_taught", outcome: true},
                  {name: "taught_at_least_one_term", outcome: true}
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

            expect { described_class.new(claim:).perform }.to(
              change { claim.tasks.count }.from(0).to(1).and(
                not_change(DfeSignIn::User, :count)
              )
            )

            task = claim.tasks.last

            expect(task.name).to eq("provider_verification")
            expect(task.passed).to eq(true)
            expect(task.manual).to eq(false)
            expect(task.created_by).to eq(user)
          end
        end
      end

      context "when the task has already been performed" do
        it "does not alter the task or create a new one" do
          eligibility = create(
            :further_education_payments_eligibility,
            verification: {
              assertions: [
                {name: "teaching_responsibilities", outcome: true}
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

          user = create(
            :dfe_signin_user,
            dfe_sign_in_id: "456",
            given_name: "Edna",
            family_name: "Krabappel"
          )

          existing_task = create(
            :task,
            claim:,
            name: "provider_verification",
            created_by: user,
            passed: false
          )

          expect { described_class.new(claim:).perform }.not_to(
            change { claim.tasks.count }
          )

          existing_task.reload

          expect(existing_task.passed).to eq(false)
          expect(existing_task.created_by).to eq(user)
        end
      end
    end
  end
end

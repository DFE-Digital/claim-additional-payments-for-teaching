require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe EyAlternativeVerification do
      subject(:verifier) { described_class.new(claim: claim) }

      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsPayments,
          eligibility: eligibility,
          date_of_birth: Date.new(1990, 1, 15),
          postcode: "SW1A 1AA",
          national_insurance_number: "QQ123456C",
          email_address: "teacher@example.com",
          first_name: "John",
          surname: "Smith",
          banking_name: banking_name,
          hmrc_bank_validation_responses: hmrc_bank_validation_responses
        )
      end

      let(:banking_name) { "John Smith" }
      let(:hmrc_bank_validation_responses) do
        [
          {
            "body" => {
              "nameMatches" => "yes"
            }
          }
        ]
      end

      let(:eligibility) do
        create(
          :early_years_payments_eligibility,
          :with_eligible_ey_provider,
          alternative_idv_claimant_employed_by_nursery: employed_by_nursery,
          alternative_idv_claimant_date_of_birth: provider_date_of_birth,
          alternative_idv_claimant_postcode: provider_postcode,
          alternative_idv_claimant_national_insurance_number: provider_nino,
          alternative_idv_claimant_email: provider_email,
          alternative_idv_claimant_bank_details_match: provider_bank_details_match
        )
      end

      let(:employed_by_nursery) { true }
      let(:provider_date_of_birth) { Date.new(1990, 1, 15) }
      let(:provider_postcode) { "SW1A 1AA" }
      let(:provider_nino) { "QQ123456C" }
      let(:provider_email) { "teacher@example.com" }
      let(:provider_bank_details_match) { true }

      describe "#perform" do
        context "when task already exists" do
          before do
            create(:task, name: "ey_alternative_verification", claim: claim)
          end

          it "does not create a new task" do
            expect { verifier.perform }.not_to change { claim.tasks.count }
          end

          it "returns nil" do
            expect(verifier.perform).to be_nil
          end
        end

        context "when provider says claimant is not employed by nursery" do
          let(:employed_by_nursery) { false }

          it "creates a failed task" do
            verifier.perform
            task = claim.tasks.find_by(name: "ey_alternative_verification")

            expect(task).to be_present
            expect(task.passed).to eq(false)
            expect(task.manual).to eq(false)
            expect(task.data).to eq({})
          end
        end

        context "when provider says claimant is employed by nursery" do
          let(:employed_by_nursery) { true }

          context "when personal details match" do
            let(:provider_date_of_birth) { Date.new(1990, 1, 15) }
            let(:provider_postcode) { "SW1A 1AA" }
            let(:provider_nino) { "QQ123456C" }
            let(:provider_email) { "teacher@example.com" }

            context "and bank details match" do
              let(:provider_bank_details_match) { true }
              let(:banking_name) { "John Smith" }

              it "creates a passed task with auto-pass flags" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to eq(true)
                expect(task.manual).to eq(false)
                expect(task.data).to eq({
                  "personal_details_were_passed_automatically" => true,
                  "personal_details_match" => true,
                  "bank_details_were_passed_automatically" => true,
                  "bank_details_match" => true
                })
              end
            end

            context "and bank details do not match (provider says no)" do
              let(:provider_bank_details_match) { false }

              it "creates an incomplete task with personal details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "personal_details_were_passed_automatically" => true,
                  "personal_details_match" => true
                })
              end
            end

            context "and HMRC name check fails" do
              let(:hmrc_bank_validation_responses) do
                [
                  {
                    "body" => {
                      "nameMatches" => "no"
                    }
                  }
                ]
              end

              it "creates an incomplete task with personal details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "personal_details_were_passed_automatically" => true,
                  "personal_details_match" => true
                })
              end
            end

            context "banking name matching scenarios" do
              let(:provider_bank_details_match) { true }

              context "when banking name exactly matches first and last name" do
                let(:claim) do
                  create(
                    :claim,
                    :submitted,
                    policy: Policies::EarlyYearsPayments,
                    eligibility: eligibility,
                    first_name: "John",
                    surname: "Smith",
                    banking_name: "John Smith",
                    hmrc_bank_validation_responses: hmrc_bank_validation_responses
                  )
                end

                it "passes bank details check" do
                  verifier.perform
                  task = claim.tasks.find_by(name: "ey_alternative_verification")
                  expect(task.data["bank_details_match"]).to eq(true)
                end
              end

              context "when banking name has middle name/initial" do
                let(:claim) do
                  create(
                    :claim,
                    :submitted,
                    policy: Policies::EarlyYearsPayments,
                    eligibility: eligibility,
                    first_name: "John",
                    surname: "Smith",
                    banking_name: "John Robert Smith",
                    hmrc_bank_validation_responses: hmrc_bank_validation_responses
                  )
                end

                it "passes bank details check" do
                  verifier.perform
                  task = claim.tasks.find_by(name: "ey_alternative_verification")
                  expect(task.data["bank_details_match"]).to eq(true)
                end
              end

              context "when banking name has extra spaces" do
                let(:claim) do
                  create(
                    :claim,
                    :submitted,
                    policy: Policies::EarlyYearsPayments,
                    eligibility: eligibility,
                    first_name: "John",
                    surname: "Smith",
                    banking_name: "  John   Smith  ",
                    hmrc_bank_validation_responses: hmrc_bank_validation_responses
                  )
                end

                it "passes bank details check (strips spaces)" do
                  verifier.perform
                  task = claim.tasks.find_by(name: "ey_alternative_verification")
                  expect(task.data["bank_details_match"]).to eq(true)
                end
              end

              context "when banking name case differs" do
                let(:claim) do
                  create(
                    :claim,
                    :submitted,
                    policy: Policies::EarlyYearsPayments,
                    eligibility: eligibility,
                    first_name: "John",
                    surname: "Smith",
                    banking_name: "JOHN SMITH",
                    hmrc_bank_validation_responses: hmrc_bank_validation_responses
                  )
                end

                it "passes bank details check (case insensitive)" do
                  verifier.perform
                  task = claim.tasks.find_by(name: "ey_alternative_verification")
                  expect(task.data["bank_details_match"]).to eq(true)
                end
              end

              context "pathological banking name cases" do
                context "when banking name is in reverse order (surname first)" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "Smith John",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name only has first name" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "John",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name only has surname" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "Smith",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name is completely different" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "Jane Doe",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name has prefix (Mr, Mrs, etc)" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "Mr John Smith",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name has suffix (Jr, Sr, etc)" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "John Smith Jr",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when banking name is hyphenated" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "Mary",
                      surname: "Smith-Jones",
                      banking_name: "Mary Smith-Jones",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "passes bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to eq(true)
                  end
                end

                context "when banking name has apostrophe" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "O'Brien",
                      banking_name: "John O'Brien",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "passes bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to eq(true)
                  end
                end

                context "when banking name has accented characters" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "José",
                      surname: "García",
                      banking_name: "José García",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "passes bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to eq(true)
                  end
                end

                context "when banking name is a substring match but doesn't start/end correctly" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "John",
                      surname: "Smith",
                      banking_name: "Johnny Smithson",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end

                context "when name contains embedded match" do
                  let(:claim) do
                    create(
                      :claim,
                      :submitted,
                      policy: Policies::EarlyYearsPayments,
                      eligibility: eligibility,
                      first_name: "Ann",
                      surname: "Smith",
                      banking_name: "Joanne Blacksmith",
                      hmrc_bank_validation_responses: hmrc_bank_validation_responses
                    )
                  end

                  it "fails bank details check" do
                    verifier.perform
                    task = claim.tasks.find_by(name: "ey_alternative_verification")
                    expect(task.data["bank_details_match"]).to be_nil
                  end
                end
              end
            end
          end

          context "when personal details do not match" do
            context "when date of birth differs" do
              let(:provider_date_of_birth) { Date.new(1990, 2, 15) }

              it "creates an incomplete task with bank details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "bank_details_were_passed_automatically" => true,
                  "bank_details_match" => true
                })
              end
            end

            context "when postcode differs (case sensitive check)" do
              let(:provider_postcode) { "sw1a 1aa" }

              it "passes when case differs (case insensitive)" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task.data["personal_details_match"]).to eq(true)
              end
            end

            context "when postcode actually differs" do
              let(:provider_postcode) { "SW1A 2AA" }

              it "creates an incomplete task with bank details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "bank_details_were_passed_automatically" => true,
                  "bank_details_match" => true
                })
              end
            end

            context "when national insurance number differs (case sensitive check)" do
              let(:provider_nino) { "qq123456c" }

              it "passes when case differs (case insensitive)" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task.data["personal_details_match"]).to eq(true)
              end
            end

            context "when national insurance number actually differs" do
              let(:provider_nino) { "QQ654321C" }

              it "creates an incomplete task with bank details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "bank_details_were_passed_automatically" => true,
                  "bank_details_match" => true
                })
              end
            end

            context "when email differs (case sensitive check)" do
              let(:provider_email) { "TEACHER@example.com" }

              it "passes when case differs (case insensitive)" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task.data["personal_details_match"]).to eq(true)
              end
            end

            context "when email actually differs" do
              let(:provider_email) { "different@example.com" }

              it "creates an incomplete task with bank details auto-passed" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({
                  "bank_details_were_passed_automatically" => true,
                  "bank_details_match" => true
                })
              end
            end

            context "when employed_by_nursery is nil" do
              let(:employed_by_nursery) { nil }

              it "creates an incomplete task without auto-pass flags" do
                verifier.perform
                task = claim.tasks.find_by(name: "ey_alternative_verification")

                expect(task).to be_present
                expect(task.passed).to be_nil
                expect(task.manual).to be_nil
                expect(task.data).to eq({})
              end
            end
          end

          context "when HMRC validation responses are empty" do
            let(:hmrc_bank_validation_responses) { [] }

            it "creates an incomplete task with personal details only" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")

              expect(task).to be_present
              expect(task.passed).to be_nil
              expect(task.data["personal_details_match"]).to eq(true)
              expect(task.data["bank_details_match"]).to be_nil
            end
          end

          context "when HMRC validation response has partial name match" do
            let(:hmrc_bank_validation_responses) do
              [
                {
                  "body" => {
                    "nameMatches" => "partial"
                  }
                }
              ]
            end

            it "creates an incomplete task" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")

              expect(task).to be_present
              expect(task.passed).to be_nil
              expect(task.data["bank_details_match"]).to be_nil
            end
          end
        end
      end
    end
  end
end

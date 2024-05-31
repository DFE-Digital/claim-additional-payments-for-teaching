require "rails_helper"

RSpec.describe BankDetailsForm do
  shared_examples "bank_details_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers"
        )
      )
    end

    let(:slug) { "personal-bank-account" }
    let(:params) do
      {
        banking_name:,
        bank_sort_code:,
        bank_account_number:,
        building_society_roll_number:,
        hmrc_validation_attempt_count:
      }
    end

    subject(:form) do
      described_class.new(
        claim: CurrentClaim.new(claims: [build(:claim)]),
        journey_session: journey_session,
        journey: journey,
        params: ActionController::Parameters.new(slug:, claim: params)
      )
    end

    let(:banking_name) { "Jo Bloggs" }
    let(:bank_sort_code) { rand(100000..999999) }
    let(:bank_account_number) { rand(10000000..99999999) }
    let(:building_society_roll_number) { nil }
    let(:hmrc_validation_attempt_count) { 0 }

    describe "#valid?" do
      context "with 200 code HMRC API response", :with_stubbed_hmrc_client do
        context "with valid account number" do
          let(:bank_account_number) { "12-34-56-78" }
          it { is_expected.to be_valid }
        end

        context "with invalid account number" do
          let(:bank_account_number) { "ABC12 34 56 789" }
          it { is_expected.not_to be_valid }
        end

        context "with blank account number" do
          let(:bank_account_number) { "" }
          it { is_expected.not_to be_valid }
        end

        context "with valid sort code" do
          let(:bank_sort_code) { "12 34 56" }
          it { is_expected.to be_valid }
        end

        context "with invalid sort code" do
          let(:bank_sort_code) { "ABC12 34 567" }
          it { is_expected.not_to be_valid }
        end

        context "with blank sort code" do
          let(:bank_sort_code) { "" }
          it { is_expected.not_to be_valid }
        end

        context "when building society" do
          let(:journey_session) do
            create(
              :"#{journey::I18N_NAMESPACE}_session",
              answers: attributes_for(
                :"#{journey::I18N_NAMESPACE}_answers",
                bank_or_building_society: "building_society"
              )
            )
          end

          context "with valid building society roll number" do
            let(:building_society_roll_number) { "CXJ-K6 897/98X" }
            it { is_expected.to be_valid }
          end

          context "with invalid building society roll number" do
            let(:building_society_roll_number) { "123456789/ABC.CD-EFGH " }
            it { is_expected.not_to be_valid }
          end

          context "with blank building society roll number" do
            let(:building_society_roll_number) { "" }
            it { is_expected.not_to be_valid }
          end
        end

        context "when HMRC bank validation is enabled", :with_hmrc_bank_validation_enabled do
          it "contacts the HMRC API" do
            form.valid?
            expect(hmrc_client).to have_received(:verify_personal_bank_account)
          end

          it "sets hmrc_api_validation_attempted" do
            form.valid?
            expect(form).to be_hmrc_api_validation_attempted
          end

          it "adds the response to the claim" do
            expect { form.valid? }.to(
              change { journey_session.reload.answers.hmrc_bank_validation_responses }
              .from([]).to([{"body" => "Test response", "code" => 200}])
            )
          end

          context "when the sort code doesn't pass basic validation" do
            let(:bank_sort_code) { 99 }

            it { is_expected.to be_invalid }

            it "does not contact the HMRC API" do
              form.valid?
              expect(hmrc_client).not_to have_received(:verify_personal_bank_account)
            end
          end

          context "when there is an HMRC validation error with the sort code" do
            let(:sort_code_correct) { false }

            it "adds an error" do
              form.valid?
              expect(form.errors[:bank_sort_code].first).to eq("Enter a valid sort code")
            end

            it "does not set hmrc_api_validation_succeeded" do
              form.valid?
              expect(form).not_to be_hmrc_api_validation_succeeded
            end
          end

          context "when the account number doesn't pass basic validation" do
            let(:bank_account_number) { 99 }

            it { is_expected.to be_invalid }

            it "does not contact the HMRC API" do
              form.valid?
              expect(hmrc_client).not_to have_received(:verify_personal_bank_account)
            end
          end

          context "when there is an HMRC validation error with the account name" do
            let(:name_match) { false }

            it "adds an error" do
              form.valid?
              expect(form.errors[:banking_name].first).to eq("Enter a valid name on the account")
            end

            it "does not set hmrc_api_validation_succeeded" do
              form.valid?
              expect(form).not_to be_hmrc_api_validation_succeeded
            end
          end

          context "when there is an error with the account number" do
            let(:account_exists) { false }

            it "adds an error" do
              form.valid?
              expect(form.errors[:bank_account_number].first).to eq("Enter the account number associated with the name on the account and/or sort code")
            end

            it "does not set hmrc_api_validation_succeeded" do
              form.valid?
              expect(form).not_to be_hmrc_api_validation_succeeded
            end
          end

          context "when the validation fails on the third attempt" do
            let(:hmrc_validation_attempt_count) { 2 }
            let(:account_exists) { false }

            it "contacts the HMRC API" do
              form.valid?
              expect(hmrc_client).to have_received(:verify_personal_bank_account)
            end

            it "does not add any errors" do
              form.valid?
              expect(form.errors[:bank_sort_code]).to be_empty
              expect(form.errors[:bank_account_number]).to be_empty
              expect(form.errors[:banking_name]).to be_empty
            end

            it "sets hmrc_api_validation_attempted" do
              form.valid?
              expect(form).to be_hmrc_api_validation_attempted
            end

            it "does not set hmrc_api_validation_succeeded" do
              form.valid?
              expect(form).not_to be_hmrc_api_validation_succeeded
            end

            it "adds the response to the claim" do
              expect { form.valid? }.to(
                change { journey_session.reload.answers.hmrc_bank_validation_responses }
                .from([]).to([{"body" => "Test response", "code" => 200}])
              )
            end
          end
        end

        context "when HMRC bank validation is disabled" do
          before { form.valid? }

          it "does not contact the HMRC API" do
            expect(hmrc_client).not_to have_received(:verify_personal_bank_account)
          end

          it "does not add any errors" do
            expect(form.errors[:bank_sort_code]).to be_empty
            expect(form.errors[:bank_account_number]).to be_empty
            expect(form.errors[:banking_name]).to be_empty
          end

          it "does not set hmrc_api_validation_succeeded" do
            form.valid?
            expect(form).not_to be_hmrc_api_validation_succeeded
          end
        end
      end

      context "when there is an HMRC API error", :with_hmrc_bank_validation_enabled, :with_failing_hmrc_bank_validation do
        it "does not add any errors" do
          form.valid?
          expect(form.errors[:bank_sort_code]).to be_empty
          expect(form.errors[:bank_account_number]).to be_empty
          expect(form.errors[:banking_name]).to be_empty
        end

        it "catches the exception" do
          expect { form.valid? }.not_to raise_error
        end

        it "does not set hmrc_api_validation_attempted" do
          form.valid?
          expect(form).not_to be_hmrc_api_validation_attempted
        end

        it "does not set hmrc_api_validation_succeeded" do
          form.valid?
          expect(form).not_to be_hmrc_api_validation_succeeded
        end

        it "adds the response to the claim" do
          expect { form.valid? }.to(
            change { journey_session.reload.answers.hmrc_bank_validation_responses }
            .from([]).to([{"body" => "Test failure", "code" => 429}])
          )
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "bank_details_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "bank_details_form", Journeys::AdditionalPaymentsForTeaching
  end
end

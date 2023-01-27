require "rails_helper"

RSpec.describe BankDetailsForm do
  let(:banking_name) { "Jo Bloggs" }
  let(:bank_sort_code) { rand(100000..999999) }
  let(:bank_account_number) { rand(10000000..99999999) }
  let(:building_society_roll_number) { nil }
  let(:claim) { build(:claim, :with_bank_details, policy: EarlyCareerPayments) }

  subject(:form) { described_class.new(claim: claim, banking_name: banking_name, bank_account_number: bank_account_number, bank_sort_code: bank_sort_code, building_society_roll_number: building_society_roll_number) }

  describe "#valid?", :with_stubbed_hmrc_client do
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
      let(:claim) { build(:claim, :with_bank_details, bank_or_building_society: :building_society, policy: EarlyCareerPayments) }

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
      before { form.valid? }

      it "contacts the HMRC API" do
        expect(hmrc_client).to have_received(:verify_personal_bank_account)
      end

      context "when there is an error with the sort code" do
        let(:sort_code_correct) { false }

        it "adds an error" do
          expect(form.errors[:bank_sort_code].first).to eq("Enter a valid sort code")
        end
      end

      context "when there is an error with the account name" do
        let(:name_match) { false }

        it "adds an error" do
          expect(form.errors[:banking_name].first).to eq("Enter a valid name on the account")
        end
      end

      context "when there is an error with the account number" do
        let(:account_exists) { false }

        it "adds an error" do
          expect(form.errors[:bank_account_number].first).to eq("Enter the account number associated with the name on the account and/or sort code")
        end
      end

      context "when there is an HMRC API error", :with_failing_hmrc_bank_validation do
        it "does not add any errors" do
          expect(form.errors[:bank_sort_code]).to be_empty
          expect(form.errors[:bank_account_number]).to be_empty
          expect(form.errors[:banking_name]).to be_empty
        end

        it "catches the exception" do
          expect { form.valid? }.not_to raise_error
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
    end
  end
end

require "rails_helper"

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob do
  let(:file_upload) do
    create(
      :file_upload,
      :with_current_academic_year,
      :not_completed_processing,
      target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
      body: file_fixture("eligible_eytfi_providers.csv").read
    )
  end

  describe "#perform" do
    it "creates eytfi provider" do
      expect {
        subject.perform(file_upload)
      }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count).by(2)
    end

    it "touches file upload completed_processing_at" do
      subject.perform(file_upload)

      expect(file_upload.reload.completed_processing_at).to be_present
    end

    context "job runs twice" do
      it "does not duplicate records" do
        expect {
          subject.perform(file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)

        expect {
          subject.perform(file_upload)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when uploads twice" do
      let(:second_file_upload) do
        create(
          :file_upload,
          :with_current_academic_year,
          :not_completed_processing,
          target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
          body: file_fixture("eligible_eytfi_providers.csv").read
        )
      end

      it "appends records" do
        expect {
          subject.perform(file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)

        expect {
          subject.perform(second_file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)
      end
    end

    context "when there is a validation error" do
      let(:file_upload) do
        create(
          :file_upload,
          :with_current_academic_year,
          :not_completed_processing,
          target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
          body: file_fixture("eligible_eytfi_providers_with_error.csv").read
        )
      end

      it "does not create any records" do
        expect {
          subject.perform(file_upload)
        }.not_to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)
      end

      it "saves errors on file upload" do
        subject.perform(file_upload)

        expect(file_upload.reload.upload_errors).to eql(["Row 4: Eligible must be TRUE or FALSE"])
      end
    end
  end
end

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob::RowParser, type: :model do
  let(:file_upload) do
    create(:file_upload)
  end

  subject { described_class.new(row:) }

  describe "#validations" do
    context "urn" do
      context "when urn missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end

      context "when urn too short" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "12345"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end

      context "when urn too long" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "123456789"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end
    end

    context "name" do
      context "name missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider name"]).to be_present
        end
      end
    end

    context "adress line 1" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider address line 1"]).to be_present
        end
      end
    end

    context "town" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider town"]).to be_present
        end
      end
    end

    context "postcode" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Postcode"]).to be_present
        end
      end
    end

    context "eligible" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Eligible"]).to be_present
        end
      end

      context "is malformatted" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "foo"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Eligible"]).to be_present
        end
      end
    end
  end

  describe "#to_provider" do
    it "returns provider object"
  end
end

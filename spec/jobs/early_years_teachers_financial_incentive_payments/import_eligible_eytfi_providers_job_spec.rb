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

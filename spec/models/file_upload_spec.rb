require "rails_helper"

RSpec.describe FileUpload, type: :model do
  describe "#delete_files" do
    let(:payroll_run1) do
      create(:payroll_run, :with_confirmations, confirmed_batches: 2, claims_counts: {
        Policies::StudentLoans => 5
      })
    end

    let(:payroll_run2) do
      create(:payroll_run, :with_confirmations, confirmed_batches: 2, claims_counts: {
        Policies::StudentLoans => 5
      })
    end

    let(:some_unrelated_file_upload) { create(:file_upload) { create(:file_upload, target_data_model: "SomeModel") } }

    before do
      travel_to Date.new(2024, 9, 15) do
        payroll_run1
        some_unrelated_file_upload
      end

      travel_to Date.new(2024, 10, 15) do
        payroll_run2
      end
    end

    it "deletes all file uploads with specified model and created earlier than specified date" do
      expected_file_upload_ids = payroll_run2.payment_confirmations.map(&:file_upload_id)

      travel_to Date.new(2024, 9, 30) do
        expect do
          FileUpload.delete_files(
            target_data_model: PaymentConfirmation,
            older_than: Time.zone.now
          )
        end.to change { FileUpload.count }.by(-2)
      end

      expect(payroll_run1.reload.payment_confirmations.map(&:file_upload_id)).to match_array([nil, nil])
      expect(payroll_run2.reload.payment_confirmations.map(&:file_upload_id)).to match_array(expected_file_upload_ids)

      # check we don't delete other file uploads for a different target_data_model
      expect { some_unrelated_file_upload.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

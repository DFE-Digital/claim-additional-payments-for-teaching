require "rails_helper"

RSpec.describe DeleteFileUploadsAndDownloadsJob do
  describe "#perform" do
    let(:payroll_run) { create(:payroll_run, :with_downloads) }

    before do
      travel_to DateTime.new(2024, 9, 15) do
        payroll_run
      end
    end

    it "calls FileUpload.delete_files for PaymentConfirmation and for the current academic year" do
      travel_to DateTime.new(2025, 8, 31, 22) do
        expect(FileUpload).to receive(:delete_files).with(target_data_model: PaymentConfirmation, older_than: DateTime.new(2025, 9, 1))

        described_class.perform_now
      end
    end

    it "calls FileDownload.delete_files for PayrollRun and for the current academic year" do
      travel_to DateTime.new(2025, 8, 31, 22) do
        expect(FileDownload).to receive(:delete_files).with(source_data_model: PayrollRun, older_than: DateTime.new(2025, 9, 1))

        described_class.perform_now
      end
    end
  end
end

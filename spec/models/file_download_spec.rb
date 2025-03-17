require "rails_helper"

RSpec.describe FileDownload, type: :model do
  describe "#delete_files" do
    let(:payroll_run1) { create(:payroll_run, :with_downloads) }
    let(:payroll_run2) { create(:payroll_run, :with_downloads) }
    let(:payroll_run3) { create(:payroll_run, :with_downloads) }

    before do
      travel_to DateTime.new(2024, 9, 15) do
        payroll_run1
      end

      travel_to DateTime.new(2024, 10, 15) do
        payroll_run2
      end

      travel_to DateTime.new(2024, 11, 15) do
        payroll_run3
      end
    end

    it "deletes all file downloads with specified model and created earlier than specified date" do
      travel_to DateTime.new(2024, 10, 31) do
        described_class.delete_files(source_data_model: PayrollRun, older_than: Time.zone.now)
      end

      file_downloads = FileDownload.all
      expect(file_downloads.count).to eq(1)
      expect(file_downloads.first.source_data_model).to eq("PayrollRun")
      expect(file_downloads.first.source_data_model_id).to eq(payroll_run3.id)
    end
  end
end

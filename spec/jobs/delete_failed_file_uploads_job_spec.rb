require "rails_helper"

RSpec.describe DeleteFailedFileUploadsJob do
  describe "#perform" do
    let!(:recent_failed_file_upload) do
      create(
        :file_upload,
        completed_processing_at: nil,
        created_at: 1.day.ago
      )
    end

    let!(:ancient_failed_file_upload) do
      create(
        :file_upload,
        completed_processing_at: nil,
        created_at: 4.months.ago
      )
    end

    it "delete failed file uploads over age threshold" do
      subject.perform

      expect(FileUpload.exists?(id: recent_failed_file_upload.id)).to be_truthy
      expect(FileUpload.exists?(id: ancient_failed_file_upload.id)).to be_falsey
    end
  end
end

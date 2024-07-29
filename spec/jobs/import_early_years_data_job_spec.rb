require "rails_helper"

RSpec.describe ImportEarlyYearsDataJob do
  describe "#perform" do
    subject(:upload) { described_class.new.perform(file_upload.id) }
    let(:file_upload) { create(:file_upload, body: csv) }
    let!(:local_authority) { create(:local_authority, code: "101") }
    let(:csv) do
      <<~CSV
        Nursery Name,EYURN / Ofsted URN,LA Code,Nursery Address,Primary Key Contact Email Address,Secondary Contact Email Address (Optional)
        Test Nursery,1234567,101,"123 Test Street, Test Town, TE1 5TT",primary@example.com,secondary@example.com
        Other Nursery,9876543,101,"321 Test Street, Test Town, TE1 5TT",primary@example.com,
      CSV
    end

    context "csv data processes successfully" do
      it "imports early years data" do
        expect { upload }.to change(EarlyYearsData, :count).by(2)
      end

      it "deletes the file upload" do
        upload

        expect(FileUpload.find_by_id(file_upload.id)).to be_nil
      end

      it "associates local authourity correctly" do
        upload

        expect(EarlyYearsData.first.nursery_name).to eq("Test Nursery")
        expect(EarlyYearsData.first.local_authority).to eq(local_authority)
      end
    end

    context "csv data encounters an error" do
      before do
        allow(EarlyYearsData).to receive(:insert_all).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not import early years data" do
        expect { upload }.not_to change(EarlyYearsData, :count)
      end

      it "keeps the file upload" do
        upload

        expect(FileUpload.find_by_id(file_upload.id)).to be_present
      end
    end
  end
end

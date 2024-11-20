require "rails_helper"

RSpec.describe ImportTeachersPensionServiceDataJob do
  describe "#perform" do
    context "csv data processes successfully" do
      let(:mail) { AdminMailer.tps_csv_processing_success(file_upload.uploaded_by.email) }
      let(:file_upload) { create(:file_upload, body: csv) }
      let(:csv) do
        <<~CSV
          Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay, ,LA URN,School URN,Employer ID
          1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,1122
        CSV
      end

      it "imports tps data, sends success email and deletes the file upload" do
        expect(EmploymentCheckJob).to receive(:perform_later)

        subject.perform(file_upload.id)

        # imports the tps data
        expect(TeachersPensionsService.count).to eq(1)

        # success email
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "5d817617-06c3-4df0-b228-f3d25510701e"

        # deletes the file upload
        expect(FileUpload.find_by_id(file_upload.id)).to be_nil
      end
    end

    context "csv data encounters an error" do
      let(:mail) { AdminMailer.tps_csv_processing_error(file_upload.uploaded_by.email) }
      let(:file_upload) { create(:file_upload, body: csv) }
      let(:csv) do
        <<~CSV
          Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay, ,LA URN,School URN,Employer ID
          1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,1122
        CSV
      end

      before do
        allow(TeachersPensionsService).to receive(:insert_all).and_raise(ActiveRecord::RecordInvalid)
        allow(Rollbar).to receive(:error)
      end

      it "sends error email and keeps the file upload" do
        subject.perform(file_upload.id)

        # error email
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "f29753a1-5b9c-4e37-8b5a-43150b3bca64"

        # Rollbar error report
        expect(Rollbar).to have_received(:error)

        # keeps the file upload for debugging
        expect(FileUpload.find_by_id(file_upload.id)).to be_present
      end
    end
  end
end

require "rails_helper"

RSpec.describe ImportStudentLoansDataJob do
  describe "#perform" do
    subject(:upload) { described_class.new.perform(file_upload.id) }
    let(:file_upload) { create(:file_upload, body: csv) }
    let(:csv) do
      <<~CSV
        Claim reference,NINO,Full name,Date of birth,Policy name,No of Plans Currently Repaying,Plan Type of Deduction,Amount
        TESTREF01,AB123456A,,20/12/1999,,,,
      CSV
    end

    context "csv data processes successfully" do
      let(:mail) { AdminMailer.slc_csv_processing_success(file_upload.uploaded_by.email) }

      it "imports student loans data" do
        expect { upload }.to change(StudentLoansData, :count).by(1)
      end

      it "deletes the file upload" do
        upload

        expect(FileUpload.find_by_id(file_upload.id)).to be_nil
      end

      it "enqueues StudentLoanAmountCheckJob" do
        expect { upload }.to have_enqueued_job(StudentLoanAmountCheckJob)
      end

      it "enqueues StudentLoanPlanCheckJob" do
        expect { upload }.to have_enqueued_job(StudentLoanPlanCheckJob)
      end

      it "sends a success email" do
        upload

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "ee4b950a-28bd-417f-a00a-bc592f18f93b"
      end
    end

    context "csv data encounters an error" do
      let(:mail) { AdminMailer.slc_csv_processing_error(file_upload.uploaded_by.email) }

      before do
        allow(StudentLoansData).to receive(:insert_all).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not import census data" do
        expect { upload }.not_to change(StudentLoansData, :count)
      end

      it "keeps the file upload" do
        upload

        expect(FileUpload.find_by_id(file_upload.id)).to be_present
      end

      it "does not enqueue StudentLoanAmountCheckJob" do
        expect { upload }.not_to have_enqueued_job(StudentLoanAmountCheckJob)
      end

      it "does not enqueue StudentLoanPlanCheckJob" do
        expect { upload }.not_to have_enqueued_job(StudentLoanPlanCheckJob)
      end

      it "sends a error email" do
        upload

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "f40fa946-963b-4ddd-a896-7c1d6bd7da12"
      end

      describe "dfe-analytics syncing" do
        it "invokes the relevant import entity job" do
          expect(AnalyticsImporter).to receive(:import).with(StudentLoansData)
          upload
        end
      end
    end
  end
end

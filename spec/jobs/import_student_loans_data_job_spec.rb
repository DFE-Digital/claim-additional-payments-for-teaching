require "rails_helper"

RSpec.describe ImportStudentLoansDataJob do
  describe "#perform" do
    subject(:upload) { described_class.new.perform(file_upload.id) }
    let(:file_upload) { create(:file_upload, body: csv) }
    let(:csv) do
      <<~CSV
        Claim reference,NINO,Full name,Date of birth,Policy name,No of Plans Currently Repaying,Plan Type of Deduction,Amount
        TESTREF01,QQ123456A,,20/12/1999,,,,
      CSV
    end

    context "csv data processes successfully" do
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
    end

    context "csv data encounters an error" do
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

      describe "dfe-analytics syncing" do
        it "invokes the relevant import entity job" do
          expect(AnalyticsImporter).to receive(:import).with(StudentLoansData)
          upload
        end
      end
    end
  end
end

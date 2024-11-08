require "rails_helper"

RSpec.describe ImportCensusJob do
  describe "#perform" do
    context "csv data processes successfully" do
      let(:mail) { AdminMailer.census_csv_processing_success(file_upload.uploaded_by.email) }
      let(:file_upload) { create(:file_upload, :school_workforce_census_upload) }

      it "imports census data, sends success email and deletes the file upload" do
        subject.perform(file_upload.id)

        # imports the census data
        expect(SchoolWorkforceCensus.count).to eq(1)

        # success email
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "81862fc7-f842-4f85-a6e7-63dffb931999"

        # deletes the file upload
        expect(FileUpload.find_by_id(file_upload.id)).to be_nil
      end
    end

    context "csv data encounters an error" do
      let(:mail) { AdminMailer.census_csv_processing_error(file_upload.uploaded_by.email) }
      let(:file_upload) { create(:file_upload, :school_workforce_census_upload) }

      before do
        allow(SchoolWorkforceCensus).to receive(:insert_all).and_raise(ActiveRecord::RecordInvalid)
        allow(Rollbar).to receive(:error)
      end

      it "does not import census data, sends error email and keeps the file upload" do
        subject.perform(file_upload.id)

        # does not import census data
        expect(SchoolWorkforceCensus.count).to eq(0)

        # error email
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(mail.template_id).to eq "873170c9-4535-441f-b929-4670f022ecc9"

        # Rollbar error report
        expect(Rollbar).to have_received(:error)

        # keeps the file upload for debugging
        expect(FileUpload.find_by_id(file_upload.id)).to be_present
      end

      describe "dfe-analytics syncing" do
        it "invokes the relevant import entity job" do
          expect(AnalyticsImporter).to receive(:import).with(SchoolWorkforceCensus)
          subject.perform(file_upload.id)
        end
      end
    end
  end
end

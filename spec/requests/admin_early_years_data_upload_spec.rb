require "rails_helper"

RSpec.describe "EY (Early Years) data upload " do
  # TODO: Set up EY journeys/check service open as required
  let!(:journey_configuration_tslr) { create(:journey_configuration, :student_loans) }
  let!(:journey_configuration_ecp_lupp) { create(:journey_configuration, :additional_payments) }
  let!(:local_authority) { create(:local_authority, code: "101") }

  before { @signed_in_user = sign_in_as_service_operator }

  describe "#new" do
    it "shows the upload form" do
      get new_admin_early_years_data_upload_path
      expect(response.body).to include("You are uploading a list of eligible nurseries and whitelisted email addresses")
    end
  end

  describe "#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "ey_data.csv") }

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }

      it "displays an error" do
        post admin_early_years_data_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_early_years_data_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "returns a unauthorized response for #{role} users" do
        sign_in_to_admin_with_role(role)

        post admin_early_years_data_uploads_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when a valid CSV is uploaded" do
      subject(:upload) do
        post admin_early_years_data_uploads_path, params: {file: file}
      end

      let(:csv) do
        <<~CSV
          Nursery Name,EYURN / Ofsted URN,LA Code,Nursery Address,Primary Key Contact Email Address,Secondary Contact Email Address (Optional)
          #{rows[0].values.join(",")}
          #{rows[1].values.join(",")}
        CSV
      end

      let(:rows) do
        [
          {
            nursery_name: "Test Nursery",
            urn: "1234567",
            local_authority_id: "101",
            nursery_address: "123 Test Street, Test Town, TE1 5ST",
            primary_key_contact_email_address: "primary@example.com",
            secondary_contact_email_address: "secondary@example.com"
          },
          {
            nursery_name: "Other Nursery",
            urn: "9876543",
            local_authority_id: "101",
            nursery_address: "321 Test Street, Test Town, TE1 5ST",
            primary_key_contact_email_address: "primary@example.com",
            secondary_contact_email_address: ""
          }
        ]
      end

      let(:expected_records) do
        rows.map do |row|
          expected_row = row.dup
          expected_row[:local_authourity] = local_authourity
          expected_row.delete :local_authority_id
          expected_row
        end
      end

      it "enqueues a job to import the file asynchronously" do
        expect { upload }.to have_enqueued_job(ImportEarlyYearsDataJob)
      end

      it "parses the rows and saves them as early years data records" do
        aggregate_failures do
          expect { perform_enqueued_jobs { upload } }.to change(EarlyYearsData, :count).by(2)
          expect(EarlyYearsData.find(urn: "1234567")).to have_attributes(expected_records[0])
          expect(EarlyYearsData.find(urn: "9876543")).to have_attributes(expected_records[1])
        end
      end

      shared_examples :no_upload do
        it "does not upload the rows" do
          expect { perform_enqueued_jobs { upload } }.not_to change(EarlyYearsData, :count)
        end
      end

      context "with rows with blank 'URN'" do
        let(:rows) { super().map { |row| row.merge(urn: "") } }

        include_examples :no_upload
      end

      context "with rows with invalid primary email" do
        let(:rows) { super().map { |row| row.merge(primary_key_contact_email_address: "") } }

        include_examples :no_upload
      end
    end
  end
end

require "rails_helper"

RSpec.describe "TPS data upload" do
  before { @signed_in_user = sign_in_as_service_operator }

  describe "tps_data_upload#new" do
    it "shows the upload form" do
      get new_admin_tps_data_upload_path
      expect(response.body).to include("Choose and upload TPS data")
    end
  end

  describe "tps_data_upload#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "tps_data.csv") }
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay, ,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
      CSV
    end

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }
      it "displays an error" do
        post admin_tps_data_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_tps_data_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "returns a unauthorized response for #{role} users" do
        sign_in_to_admin_with_role(role)

        post admin_tps_data_uploads_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

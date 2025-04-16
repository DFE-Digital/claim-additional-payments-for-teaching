require "rails_helper"

RSpec.describe "School workforce census data upload" do
  before { @signed_in_user = sign_in_as_service_operator }

  describe "school_workforce_census_data_upload#new" do
    it "shows the upload form" do
      get new_admin_school_workforce_census_data_upload_path
      expect(response.body).to include("Choose and upload School Workforce Census data")
    end
  end

  describe "school_workforce_census_data_upload#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "school_workforce_census_data.csv") }
    let(:csv) do
      <<~CSV
        TRN,'GeneralSubjectDescription,1st occurance',2nd,3rd,4th,5th
        1234567,English,Physical Education,,,,
      CSV
    end

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }
      it "displays an error" do
        post admin_school_workforce_census_data_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_school_workforce_census_data_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    it "returns a unauthorized response for support agents" do
      sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)

      post admin_school_workforce_census_data_uploads_path

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

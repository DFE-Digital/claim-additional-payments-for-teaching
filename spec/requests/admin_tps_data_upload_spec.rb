require "rails_helper"

RSpec.describe "TPS data upload" do
  before { @signed_in_user = sign_in_as_service_operator }

  describe "#new" do
    it "shows the upload form" do
      get new_admin_tps_data_upload_path
      expect(response.body).to include("Choose and upload TPS data")
    end
  end

  describe "#create" do
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

    context "when a valid CSV is uploaded" do
      let(:csv) do
        <<~CSV
          Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
          1000106,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,370,4027
          1000107,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,111,2222
        CSV
      end

      let!(:claim_matched) do
        create(
          :claim,
          :submitted,
          teacher_reference_number: 1000106,
          submitted_at: Date.new(2022, 7, 15)
        )
      end

      let!(:claim_no_match) do
        create(
          :claim,
          :submitted,
          teacher_reference_number: 1000107,
          submitted_at: Date.new(2022, 7, 15)
        )
      end

      let!(:claim_no_data) { create(:claim, :submitted) }

      it "runs the tasks, adds notes and redirects to the right page" do
        expect { post admin_tps_data_uploads_path, params: {file: file} }.to(
          change do
            [
              claim_matched.reload.tasks.size,
              claim_no_match.reload.tasks.size,
              claim_no_data.reload.tasks.size,
              claim_matched.reload.notes.size,
              claim_no_match.reload.notes.size,
              claim_no_data.reload.notes.size
            ]
          end
        )

        expect(claim_matched.tasks.last.claim_verifier_match).to eq "all"
        expect(claim_no_match.tasks.last.claim_verifier_match).to eq "none"
        expect(claim_no_data.tasks.last.claim_verifier_match).to be_nil
        expect(claim_matched.notes.last[:body]).to eq "[Employment] - Eligible:\n<pre>School 1: LA Code: 370 / Establishment Number: 4027\n</pre>\n"
        expect(claim_no_match.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>School 1: LA Code: 111 / Establishment Number: 2222\n</pre>\n"
        expect(claim_no_data.notes.last[:body]).to eq "[Employment] - No data"

        expect(response).to redirect_to(admin_claims_path)
      end
    end
  end
end

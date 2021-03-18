require "rails_helper"

RSpec.describe "Admin qualification report upload" do
  before { @signed_in_user = sign_in_as_service_operator }

  describe "qualification_report_upload#new" do
    it "shows the upload form" do
      get new_admin_qualification_report_upload_path
      expect(response.body).to include("Choose and upload DQT report")
    end
  end

  describe "qualification_report_upload#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "dqt_data.csv") }
    let(:csv) do
      <<~CSV
        dfeta text1,dfeta text2,dfeta trn,fullname,birthdate,dfeta ninumber,dfeta qtsdate,dfeta he hesubject1idname,dfeta he hesubject2idname,dfeta he hesubject3idname,HESubject1Value,HESubject2Value,HESubject3Value,dfeta subject1idname,dfeta subject2idname,dfeta subject3idname,ITTSub1Value,ITTSub2Value,ITTSub3Value
        1234567,#{claim.reference},1234567,Fred Smith,23/8/1990,QQ123456C,23/8/2017,Politics,,,L200,,,Mathematics,,,G100,,
      CSV
    end
    let(:claim) do
      create(:claim, :submitted,
        teacher_reference_number: "1234567",
        first_name: "Fred",
        surname: "Smith",
        date_of_birth: Date.new(1990, 8, 23),
        eligibility: build(:maths_and_physics_eligibility, :eligible))
    end

    context "when the data in CSV matches the data in the claim" do
      it "creates qualification and identity_confirmation tasks for the claim" do
        expect {
          post admin_qualification_report_uploads_path, params: {file: file}
        }.to change { claim.tasks.count }.by(2)

        qualification_task = claim.tasks.find_by(name: "qualifications")
        expect(qualification_task.created_by).to eql(@signed_in_user)

        id_confirmation_task = claim.tasks.find_by(name: "identity_confirmation")
        expect(id_confirmation_task.created_by).to eql(@signed_in_user)

        expect(flash[:notice]).to eql("DQT report uploaded successfully. Automatically completed 2 tasks for 1 checked claim.")
        expect(response).to redirect_to(admin_claims_path)
      end
    end

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }
      it "displays an error" do
        post admin_qualification_report_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_qualification_report_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    context "when there's an ActiveRecord::RecordInvalid error raised during the file ingest" do
      it "displays an error and prompts the user to try again" do
        expect_any_instance_of(AutomatedChecks::DqtReportConsumer).to receive("ingest").and_raise(ActiveRecord::RecordInvalid)

        expect {
          post admin_qualification_report_uploads_path, params: {file: file}
        }.not_to change { Task.count }

        expect(response).to redirect_to(new_admin_qualification_report_upload_path)
        expect(flash[:alert]).to eql("There was a problem, please try again")
      end
    end

    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "returns a unauthorized response for #{role} users" do
        sign_in_to_admin_with_role(role)

        post admin_qualification_report_uploads_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

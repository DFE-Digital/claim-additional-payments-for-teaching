require "rails_helper"

RSpec.describe "SLC (Student Loans Company) data upload " do
  let!(:journey_configuration_tslr) { create(:journey_configuration, :student_loans) }
  let!(:journey_configuration_ecp_lupp) { create(:journey_configuration, :additional_payments) }
  let!(:journey_configuration_fe) { create(:journey_configuration, :further_education_payments) }
  let!(:journey_configuration_ey) { create(:journey_configuration, :early_years_payment_provider_start) }

  before { @signed_in_user = sign_in_as_service_operator }

  describe "#new" do
    it "shows the upload form" do
      get new_admin_student_loans_data_upload_path
      expect(response.body).to include("Choose and upload SLC data")
    end
  end

  describe "#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "slc_data.csv") }

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }

      it "displays an error" do
        post admin_student_loans_data_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_student_loans_data_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "returns a unauthorized response for #{role} users" do
        sign_in_to_admin_with_role(role)

        post admin_student_loans_data_uploads_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when a valid CSV is uploaded" do
      subject(:upload) do
        post admin_student_loans_data_uploads_path, params: {file: file}
      end

      let(:csv) do
        <<~CSV
          Claim reference,NINO,Full name,Date of birth,Policy name,No of Plans Currently Repaying,Plan Type of Deduction,Amount
          #{rows.map { |row| row.values.join(",") }.join("\n")}
        CSV
      end

      let(:rows) do
        [
          {
            claim_reference: "TESTREF01",
            nino: "QQ123456A",
            full_name: "John Doe",
            date_of_birth: "1/12/1989",
            policy_name: "EarlyCareerPayments",
            no_of_plans_currently_repaying: "1",
            plan_type_of_deduction: "1",
            amount: "10"
          },
          {
            claim_reference: "TESTREF02",
            nino: "QQ123456B",
            full_name: "Agata Christie",
            date_of_birth: "20/03/1977",
            policy_name: "LevellingUpPremiumPayments",
            no_of_plans_currently_repaying: "1",
            plan_type_of_deduction: "2",
            amount: "50"
          },
          {
            claim_reference: "TESTREF03",
            nino: "QQ234567B",
            full_name: "Guybrush Threepwood",
            date_of_birth: "1/12/1980",
            policy_name: "EarlyCareerPayments",
            no_of_plans_currently_repaying: "No data",
            plan_type_of_deduction: "No data",
            amount: "No data"
          }
        ]
      end

      let(:expected_records) do
        rows.map do |row|
          {
            claim_reference: row[:claim_reference],
            nino: row[:nino],
            full_name: row[:full_name],
            date_of_birth: Date.strptime(row[:date_of_birth], "%d/%m/%Y"),
            policy_name: row[:policy_name],
            no_of_plans_currently_repaying: row[:no_of_plans_currently_repaying].to_i,
            plan_type_of_deduction: row[:plan_type_of_deduction].to_i,
            amount: row[:amount].to_i
          }
        end
      end

      it "enqueues a job to import the file asynchronously" do
        expect { upload }.to have_enqueued_job(ImportStudentLoansDataJob)
      end

      it "parses the rows with data and saves them as student loans data records" do
        aggregate_failures do
          expect { perform_enqueued_jobs { upload } }.to change(StudentLoansData, :count).by(3)
          expect(StudentLoansData.where(nino: "QQ123456A").first).to have_attributes(expected_records[0])
          expect(StudentLoansData.where(nino: "QQ123456B").first).to have_attributes(expected_records[1])
        end
      end

      it "parses the rows with no data and saves them as student loans data records" do
        perform_enqueued_jobs { upload }
        expect(StudentLoansData.where(nino: "QQ234567B").first).to have_attributes(
          {
            claim_reference: "TESTREF03",
            nino: "QQ234567B",
            full_name: "Guybrush Threepwood",
            date_of_birth: Date.strptime("1/12/1980", "%d/%m/%Y"),
            policy_name: "EarlyCareerPayments",
            no_of_plans_currently_repaying: nil,
            plan_type_of_deduction: nil,
            amount: 0
          }
        )
      end

      shared_examples :no_upload do
        it "does not upload the rows" do
          expect { perform_enqueued_jobs { upload } }.not_to change(StudentLoansData, :count)
        end
      end

      context "with rows with blank 'NINO'" do
        let(:rows) { super().map { |row| row.merge(nino: "") } }

        include_examples :no_upload
      end

      context "with rows with invalid 'Date of Birth'" do
        let(:rows) { super().map { |row| row.merge(date_of_birth: "12/20/1999") } }

        include_examples :no_upload
      end
    end
  end
end

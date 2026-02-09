require "rails_helper"

RSpec.describe "Test data downloads", type: :request do
  describe "GET /testdata" do
    it "returns a successful response" do
      get test_data_path

      expect(response).to have_http_status(:ok)
    end

    it "lists persona download labels" do
      get test_data_path

      expect(response.body).to include("Student Loans")
      expect(response.body).to include("Schools Targeted Retentions Incentive")
    end

    it "lists generated file download labels" do
      get test_data_path

      expect(response.body).to include("TRS Data")
      expect(response.body).to include("School Workforce Census")
      expect(response.body).to include("STRI Awards")
      expect(response.body).to include("Teachers Pensions Service")
    end
  end

  describe "GET /testdata/download/:file_key" do
    context "with a persona file" do
      it "returns a CSV file" do
        get test_data_download_path(file_key: "student_loans_personas")

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to include("text/csv")
      end
    end

    context "with a generated file" do
      it "returns a CSV file" do
        csv_table = CSV::Table.new([CSV::Row.new(["col"], ["val"])])
        allow(Policies::TargetedRetentionIncentivePayments::Test::TrsDataGenerator).to receive(:to_csv).and_return(csv_table)

        get test_data_download_path(file_key: "trs_data")

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to include("text/csv")
      end
    end

    context "with an invalid file key" do
      it "returns not found" do
        get test_data_download_path(file_key: "nonexistent")

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

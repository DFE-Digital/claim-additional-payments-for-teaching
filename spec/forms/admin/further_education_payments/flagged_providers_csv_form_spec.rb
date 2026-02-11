require "rails_helper"

RSpec.describe Admin::FurtherEducationPayments::FlaggedProvidersCsvForm do
  describe "validations" do
    it "validates the csv is valid" do
      csv = <<~CSV
        hello"
      CSV

      data = StringIO.new(csv)

      file = Rack::Test::UploadedFile.new(data, original_filename: "provider.csv")

      form = described_class.new(
        admin: create(:dfe_signin_user, :service_admin),
        file: file
      )

      expect(form).not_to be_valid

      expect(form.errors[:file]).to include "CSV file is invalid"
    end

    it "validates the csv has the expected headers" do
      csv = <<~CSV
        ukrnp,reasons
        12345678,clawback
        4567890,clawback
      CSV

      data = StringIO.new(csv)

      file = Rack::Test::UploadedFile.new(data, original_filename: "provider.csv")

      form = described_class.new(
        admin: create(:dfe_signin_user, :service_admin),
        file: file
      )

      expect(form).not_to be_valid

      expect(form.errors[:file]).to(
        include("Missing expected headers 'ukprn,reason'")
      )
    end

    it "validates all rows have a ukprn matching a provider" do
      create(:eligible_fe_provider, ukprn: 12345678)

      csv = <<~CSV
        ukprn,reason
        12345678,clawback
        4567890,clawback
      CSV

      data = StringIO.new(csv)

      file = Rack::Test::UploadedFile.new(data, original_filename: "provider.csv")

      form = described_class.new(
        admin: create(:dfe_signin_user, :service_admin),
        file: file
      )

      expect(form).not_to be_valid

      expect(form.errors[:file]).to(
        include("Ukprn provider with UKPRN 4567890 not found")
      )
    end
  end

  describe "#save" do
    context "when valid" do
      it "creates flags for the providers" do
        provider = create(:eligible_fe_provider, ukprn: 12345678)

        csv = <<~CSV
          ukprn,reason
          12345678,clawback
        CSV

        data = StringIO.new(csv)

        file = Rack::Test::UploadedFile.new(data, original_filename: "provider.csv")

        form = described_class.new(
          admin: create(:dfe_signin_user, :service_admin),
          file: file
        )

        form.save

        expect(provider).to be_flagged
      end
    end
  end
end

require "rails_helper"

RSpec.describe "SchoolDataImporterJob" do
  describe "#perform" do
    it "should run the school data importer" do
      expect_any_instance_of(SchoolDataImporter).to receive(:run)

      SchoolDataImporterJob.new.perform
    end
  end
end

require "rails_helper"
require "csv"

RSpec.describe SchoolDataImporter do
  let(:school_data_importer) { SchoolDataImporter.new }

  describe "#run" do
    let(:date_string) { Time.zone.now.strftime("%Y%m%d") }
    let(:gias_csv_url) { "http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata#{date_string}.csv" }
    let(:example_csv_file) { File.open("spec/fixtures/example_schools_data.csv") }
    let!(:request) { stub_request(:get, gias_csv_url).to_return(body: example_csv_file) }

    it "downloads the Get Information About Schools CSV file" do
      school_data_importer.run

      expect(request).to have_been_requested
    end

    context "when the download is successful" do
      it "imports each row as a school with associated Local Authority" do
        expect { school_data_importer.run }.to change { School.count }.by 2

        imported_school = School.find_by(urn: 106653)
        expect(imported_school.name).to eql("Penistone Grammar School")
        expect(imported_school.street).to eql("Huddersfield Road")
        expect(imported_school.phase).to eql("secondary")
        expect(imported_school.school_type).to eql("community_school")
        expect(imported_school.school_type_group).to eql("la_maintained")
        expect(imported_school.local_authority.code).to eql(370)
        expect(imported_school.local_authority.name).to eql("Barnsley")
      end

      it "correctly handles any Latin1 encoded characters in the data file" do
        school_data_importer.run

        imported_school = School.find_by(urn: 126416)
        expect(imported_school.name).to eql("St Thomas à Becket Church of England Aided Primary School")
      end

      context "when the school data is invalid" do
        let(:example_csv_file) { File.open("spec/fixtures/example_bad_schools_data.csv") }

        it "raises an ActiveRecord::RecordInvalid exception" do
          expect { school_data_importer.run }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when the school already exists" do
        let!(:existing_school) { create(:school, urn: 106653, name: "Penistone Secondary School") }

        it "updates the school record" do
          school_data_importer.run
          existing_school.reload

          expect(existing_school.name).to eql("Penistone Grammar School")
        end
      end

      context "when the local authority already exists" do
        let!(:existing_la) { create(:local_authority, code: 370, name: "South Yorkshire") }

        it "updates the local authority record" do
          school_data_importer.run
          existing_la.reload

          expect(existing_la.name).to eql("Barnsley")
        end
      end
    end
  end

  describe "#schools_data_file" do
    let(:date_string) { Time.zone.now.strftime("%Y%m%d") }
    let(:gias_csv_url) { "http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata#{date_string}.csv" }
    let(:example_csv_file) { File.open("spec/fixtures/example_schools_data.csv") }
    let!(:request) { stub_request(:get, gias_csv_url).to_return(body: example_csv_file) }

    it "returns the GIAS data as a Tempfile (and not StringIO) so CSV.foreach can be used to stream-read the data" do
      file = school_data_importer.schools_data_file

      expect(file).to be_a(Tempfile)
      expect(FileUtils.identical?(file.path, example_csv_file.path)).to be_truthy
    end
  end
end

require "rails_helper"
require "csv"

RSpec.describe SchoolDataImporter do
  let(:school_data_importer) { SchoolDataImporter.new }
  let(:example_csv_file) { File.open("spec/fixtures/files/example_schools_data.csv") }

  describe "#run" do
    it "downloads the file from a location based on the current date" do
      travel_to Date.new(2020, 12, 3) do
        expected_location = "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata20201203.csv"
        expected_request = stub_request(:get, expected_location).to_return(body: example_csv_file)

        school_data_importer.run

        expect(expected_request).to have_been_requested
      end
    end

    context "with a successful CSV download" do
      around do |example|
        travel_to(Date.new(2019, 1, 23)) { example.run }
      end

      let(:todays_file_url) { "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata20190123.csv" }
      let!(:request) { stub_request(:get, todays_file_url).to_return(body: example_csv_file) }

      it "imports each row as a school with associated Local Authority" do
        expect { school_data_importer.run }.to change { School.count }.by 3
        expect(request).to have_been_requested

        imported_school = School.find_by(urn: 106653)
        expect(imported_school.name).to eql("Penistone Grammar School")
        expect(imported_school.street).to eql("Huddersfield Road")
        expect(imported_school.phase).to eql("secondary")
        expect(imported_school.school_type).to eql("community_school")
        expect(imported_school.school_type_group).to eql("la_maintained")
        expect(imported_school.local_authority.code).to eql(370)
        expect(imported_school.local_authority.name).to eql("Barnsley")
        expect(imported_school.local_authority_district.code).to eql("E08000016")
        expect(imported_school.local_authority_district.name).to eql("Barnsley")
        expect(imported_school.close_date).to be_nil
        expect(imported_school.establishment_number).to eq(4027)
        expect(imported_school.statutory_high_age).to eq(18)
        expect(imported_school.phone_number).to eq("01226762114")
      end

      it "imports a closed school with the date it closed" do
        school_data_importer.run

        closed_school = School.find_by(urn: 117137)
        expect(closed_school.name).to eql("Fleetville Junior School")
        expect(closed_school.close_date).to eql(Date.new(2012, 5, 31))
      end

      it "correctly handles any Latin1 encoded characters in the data file" do
        school_data_importer.run

        imported_school = School.find_by(urn: 126416)
        expect(imported_school.name).to eql("St Thomas à Becket Church of England Aided Primary School")
      end

      context "when the school data is invalid" do
        let(:example_csv_file) { File.open("spec/fixtures/files/example_bad_schools_data.csv") }

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
        before do
          local_authorities(:barnsley).update!(name: "South Yorkshire")
        end

        it "updates the local authority record" do
          school_data_importer.run
          local_authorities(:barnsley).reload

          expect(local_authorities(:barnsley).name).to eql("Barnsley")
        end
      end

      context "when the local authority district already exists" do
        before do
          local_authority_districts(:barnsley).update!(name: "South Yorkshire")
        end

        it "updates the local authority district" do
          school_data_importer.run
          local_authority_districts(:barnsley).reload

          expect(local_authority_districts(:barnsley).name).to eql("Barnsley")
        end
      end
    end
  end
end

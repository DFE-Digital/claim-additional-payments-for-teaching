require "rails_helper"

RSpec.describe AutomatedChecks::DQTReportCsvToRecords do
  subject(:dqt_report_csv_to_records) { described_class.new(rows) }
  let(:rows) do
    [
      {
        "dfeta text2" => "AB123456",
        "dfeta qtsdate" => "24/10/2017",
        "birthdate" => "10/09/1980",
        "HESubject1Value" => "G100",
        "HESubject2Value" => "F100",
        "HESubject3Value" => nil,
        "ITTSub1Value" => "E100",
        "ITTSub2Value" => nil,
        "ITTSub3Value" => nil
      },
      {
        "dfeta text2" => "AB123456",
        "dfeta qtsdate" => "24/10/2017",
        "birthdate" => "10/09/1980",
        "HESubject1Value" => "R100",
        "HESubject2Value" => nil,
        "HESubject3Value" => nil,
        "ITTSub1Value" => "E100",
        "ITTSub2Value" => nil,
        "ITTSub3Value" => nil
      },
      {
        "dfeta text2" => "XX999999",
        "dfeta qtsdate" => "17/06/2016",
        "birthdate" => "05/03/1993",
        "HESubject1Value" => "X100",
        "HESubject2Value" => nil,
        "HESubject3Value" => nil,
        "ITTSub1Value" => "X100",
        "ITTSub2Value" => nil,
        "ITTSub3Value" => nil
      }
    ]
  end

  describe "#transform" do
    it "transforms multiple rows with the same reference to unique records" do
      expected_records = [
        {
          claim_reference: "AB123456",
          qts_date: Date.new(2017, 10, 24),
          date_of_birth: Date.new(1980, 9, 10),
          degree_jac_codes: ["G100", "F100", "R100"],
          itt_subject_jac_codes: ["E100"]
        },
        {
          claim_reference: "XX999999",
          qts_date: Date.new(2016, 6, 17),
          date_of_birth: Date.new(1993, 3, 5),
          degree_jac_codes: ["X100"],
          itt_subject_jac_codes: ["X100"]
        }
      ]
      expect(dqt_report_csv_to_records.transform).to eql(expected_records)
    end
  end

  context "when there is no qualification data in the record" do
    let(:rows) do
      [
        {
          "dfeta text2" => "RE123456",
          "dfeta qtsdate" => nil,
          "birthdate" => "24/03/1988",
          "HESubject1Value" => nil,
          "HESubject2Value" => nil,
          "HESubject3Value" => nil,
          "ITTSub1Value" => nil,
          "ITTSub2Value" => nil,
          "ITTSub3Value" => nil
        }
      ]
    end

    it "handles nil values" do
      expected_records = [
        {
          claim_reference: "RE123456",
          qts_date: nil,
          date_of_birth: Date.new(1988, 3, 24),
          degree_jac_codes: [],
          itt_subject_jac_codes: []
        }
      ]
      expect(dqt_report_csv_to_records.transform).to eql(expected_records)
    end
  end
end

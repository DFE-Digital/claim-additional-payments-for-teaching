require "rails_helper"

RSpec.describe AutomatedChecks::DqtReportCsvToRecords do
  subject(:dqt_report_csv_to_records) { described_class.new(rows) }
  let(:rows) do
    [
      {
        "dfeta text2" => "AB123456",
        "dfeta trn" => "1234567",
        "dfeta qtsdate" => "24/10/2017",
        "fullname" => "Jonathan Bishop",
        "birthdate" => "10/09/1980",
        "dfeta ninumber" => "QQ123456C",
        "HESubject1Value" => "G100",
        "HESubject2Value" => "F100",
        "HESubject3Value" => nil,
        "ITTSub1Value" => "E100",
        "ITTSub2Value" => nil,
        "ITTSub3Value" => nil
      },
      {
        "dfeta text2" => "AB123456",
        "dfeta trn" => "1234567",
        "dfeta qtsdate" => "24/10/2017",
        "fullname" => "Jonathan Bishop",
        "birthdate" => "10/09/1980",
        "dfeta ninumber" => "QQ123456C",
        "HESubject1Value" => "R100",
        "HESubject2Value" => nil,
        "HESubject3Value" => nil,
        "ITTSub1Value" => "E100",
        "ITTSub2Value" => nil,
        "ITTSub3Value" => nil
      },
      {
        "dfeta text2" => "XX999999",
        "dfeta trn" => "7654321",
        "dfeta qtsdate" => "17/06/2016",
        "fullname" => "Phillip David Collins",
        "birthdate" => "05/03/1993",
        "dfeta ninumber" => "QQ123456B",
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
          teacher_reference_number: "1234567",
          qts_date: Date.new(2017, 10, 24),
          first_name: "Jonathan",
          surname: "Bishop",
          date_of_birth: Date.new(1980, 9, 10),
          national_insurance_number: "QQ123456C",
          degree_codes: ["G100", "F100", "R100"],
          itt_subject_codes: ["E100"]
        },
        {
          claim_reference: "XX999999",
          teacher_reference_number: "7654321",
          qts_date: Date.new(2016, 6, 17),
          first_name: "Phillip",
          surname: "Collins",
          date_of_birth: Date.new(1993, 3, 5),
          national_insurance_number: "QQ123456B",
          degree_codes: ["X100"],
          itt_subject_codes: ["X100"]
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
          "dfeta trn" => nil,
          "dfeta qtsdate" => nil,
          "fullname" => nil,
          "birthdate" => "24/03/1988",
          "dfeta ninumber" => nil,
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
          teacher_reference_number: nil,
          qts_date: nil,
          first_name: nil,
          surname: nil,
          date_of_birth: Date.new(1988, 3, 24),
          national_insurance_number: nil,
          degree_codes: [],
          itt_subject_codes: []
        }
      ]
      expect(dqt_report_csv_to_records.transform).to eql(expected_records)
    end
  end
end

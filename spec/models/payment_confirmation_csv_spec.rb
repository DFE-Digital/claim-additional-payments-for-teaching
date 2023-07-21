require "rails_helper"

RSpec.describe PaymentConfirmationCsv do
  subject { described_class.new(file) }

  let(:file) do
    Tempfile.new.tap do |file|
      file.write(csv)
      file.rewind
    end
  end

  context "when the CSV is valid and has all the correct data" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
        DFE00001,448.5,88b5dba7-ccf1-4ffd-a3ce-20bd3ce1e500,33.9,38.98,0,89.6,325,"MathsAndPhysics StudentLoans",0.00,17/07/2023
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Payroll Reference"]).to eq("DFE00001")
    end
  end

  context "when the CSV is malformed" do
    let(:csv) do
      <<~CSV
        "1","2","3" "
      CSV
    end

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["The selected file must be a CSV"])
    end
  end

  context "when the CSV does not have the expected headers" do
    let(:csv) do
      <<~CSV
        Payroll Ref,Gross Val,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies
        DFE00001,448.5,88b5dba7-ccf1-4ffd-a3ce-20bd3ce1e500,33.9,38.98,0,89.6,325,StudentLoans
      CSV
    end

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["The selected file is missing some expected columns: Payroll Reference, Gross Value, Postgraduate Loans, Payment Date"])
    end
  end

  context "when the CSV is not present" do
    let(:file) { nil }

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["Select a file"])
    end
  end

  context "when the CSV contains a byte order mark (BOM)" do
    let(:file) do
      Tempfile.new.tap do |file|
        file.write(byte_order_mark + csv)
        file.rewind
      end
    end
    let(:byte_order_mark) { "\xEF\xBB\xBF" }
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Payment ID,NI,Employers NI,Student Loans,Tax,Net Pay,Claim Policies,Postgraduate Loans,Payment Date
        DFE00001,448.5,88b5dba7-ccf1-4ffd-a3ce-20bd3ce1e500,33.9,38.98,0,89.6,325,StudentLoans,0.00,17/07/2023
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Payroll Reference"]).to eq("DFE00001")
    end
  end
end

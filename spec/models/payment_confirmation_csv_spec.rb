require "rails_helper"

RSpec.describe PaymentConfirmationCsv do
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end

  subject { described_class.new(file) }

  context "The CSV is valid and has all the correct data" do
    let(:csv) do
      <<~CSV
        Payroll Reference,Gross Value,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,ABC123,33.9,38.98,0,89.6,325
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Payroll Reference"]).to eq("DFE00001")
    end
  end

  context "The CSV is malformed" do
    let(:csv) do
      <<~CSV
        "1","2","3" "
      CSV
    end

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["The selected file must be a CSV"])
    end
  end

  context "The CSV does not have the expected headers" do
    let(:csv) do
      <<~CSV
        Payroll Ref,Gross Val,Claim ID,NI,Employers NI,Student Loans,Tax,Net Pay
        DFE00001,487.48,ABC123,33.9,38.98,0,89.6,325
      CSV
    end

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["The selected file is missing some expected columns: Payroll Reference, Gross Value"])
    end
  end

  context "The CSV is not present" do
    let(:file) { nil }

    it "fails and populates its errors" do
      expect(subject.errors).to eq(["You must provide a file"])
    end
  end
end

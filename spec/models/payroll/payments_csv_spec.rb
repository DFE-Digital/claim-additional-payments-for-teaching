require "rails_helper"

RSpec.describe Payroll::PaymentsCsv do
  subject(:generator) { described_class.new(payroll_run) }

  let(:payroll_run) do
    create(:payroll_run, claims_counts: {Policies::StudentLoans => 1, Policies::EarlyCareerPayments => 2}, created_at: creation_date)
  end
  let(:creation_date) { "2023-07-17" }

  def generate_csv(payments)
    csv_headers = Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.values
    csv_header_row = CSV.generate_line(csv_headers).chomp

    csv_payment_rows = payments.map do |payment|
      Payroll::PaymentCsvRow.new(payment).to_s.chomp
    end

    [csv_header_row, csv_payment_rows].join("\n") + "\n"
  end

  def load_zip(buffer)
    Zip::File.open_buffer(buffer)
  end

  def extract(data, index)
    load_zip(data).zip.flatten[index - 1]
  end

  def extract_csv_name(data, index)
    extract(data, index).name
  end

  def extract_csv_content(data, index)
    extract(data, index).get_input_stream.read
  end

  describe "#data" do
    subject(:data) { generator.data }

    let(:payments_batch_one) { payroll_run.payments.ordered.first(2) }
    let(:payments_batch_two) { [payroll_run.payments.ordered.last] }

    let(:csv_batch_one) { generate_csv(payments_batch_one) }
    let(:csv_batch_two) { generate_csv(payments_batch_two) }

    let(:max_batch_size) { 2 }

    before do
      stub_const("PayrollRun::MAX_BATCH_SIZE", max_batch_size)
    end

    it "produces a zip file" do
      expect(load_zip(data)).to be_truthy
    end

    context "zip file" do
      it "contains CSVs with the batch number in the filename", :aggregate_failures do
        expect(extract_csv_name(data, 1)).to eq("payroll_data_#{creation_date}-batch_1.csv")
        expect(extract_csv_name(data, 2)).to eq("payroll_data_#{creation_date}-batch_2.csv")
      end

      it "contains CSVs with batched payment data", :aggregate_failures do
        expect(extract_csv_content(data, 1)).to eq(csv_batch_one)
        expect(extract_csv_content(data, 2)).to eq(csv_batch_two)
      end
    end
  end

  describe "#content_type" do
    it { expect(generator.content_type).to eq("application/zip") }
  end

  describe "#filename" do
    it "returns a ZIP filename that includes the date of the payroll run" do
      expect(generator.filename).to eq("payroll_data_#{creation_date}.zip")
    end
  end
end

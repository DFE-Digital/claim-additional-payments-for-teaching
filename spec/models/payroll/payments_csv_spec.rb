require "rails_helper"

RSpec.describe Payroll::PaymentsCsv do
  subject(:generator) { described_class.new(payroll_run) }

  let(:payroll_run) do
    create(
      :payroll_run,
      claims_counts: {
        Policies::StudentLoans => 1,
        Policies::EarlyCareerPayments => 2
      },
      created_at: creation_date
    )
  end

  let(:creation_date) { "2023-07-17" }

  let(:rows) do
    generator.data.split("\r\n").map { |row| row.split(",") }
  end

  describe "#data" do
    describe "CSV headers" do
      subject(:headers) { rows.first }

      it { is_expected.to eq(described_class::FIELDS_WITH_HEADERS.values) }
    end

    describe "CSV content" do
      subject(:body) { rows[1..] }

      it do
        is_expected.to match_array(
          payroll_run.payments.map do |payment|
            Payroll::PaymentCsvRow.new(payment).to_a.map(&:to_s)
          end
        )
      end
    end
  end

  describe "#content_type" do
    subject { generator.content_type }
    it { is_expected.to eq("text/csv") }
  end
end

require "rails_helper"

RSpec.describe TslrClaimsCsv do
  subject { described_class.new(claims) }
  let(:claims) { create_list(:tslr_claim, 5, :eligible_and_submittable) }

  it "initializes correctly" do
    expect(subject.claims.count).to eq(5)
    expect(subject.claims.first).to be_a(TslrClaim)
  end

  describe "csv_headers" do
    let(:csv_headers) { subject.csv_headers }
    let(:number_of_fields) { described_class::FIELDS.count }

    it "returns the headers" do
      expect(csv_headers.count).to eq(number_of_fields)
    end

    it "fetches the translations for each field" do
      expect(subject).to receive(:header_string_for_field).exactly(number_of_fields).times
      csv_headers
    end
  end

  describe "header_string_for_field" do
    let(:field) { "foo" }
    let(:header_string_for_field) { subject.send(:header_string_for_field, field) }

    it "fetches a translation" do
      expect(I18n).to receive(:t).with("tslr.csv_headers.#{field}")
      header_string_for_field
    end
  end
end

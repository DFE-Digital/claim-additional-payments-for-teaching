require "rails_helper"

RSpec.describe TslrClaimsCsv do
  before do
    create_list(:tslr_claim, 5, :eligible_and_submittable)
  end

  subject { described_class.new(claims) }
  let(:claims) { TslrClaim.all }

  describe "file" do
    let(:file) { subject.file }
    let(:csv) { CSV.read(file) }

    it "returns a csv" do
      expect(csv.count).to eq(6)
      expect(csv.first).to eq(subject.send(:csv_headers))
      subject.claims.each_with_index do |claim, i|
        row = TslrClaimCsvRow.new(claim).send(:data)
        expect(csv[i + 1]).to eq(row)
      end
    end
  end
end

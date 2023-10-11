require "rails_helper"

RSpec.describe SchoolWorkforceCensus do
  context "when there are submitted claims" do
    let(:submitted_claims) { create_list(:claim, 15, :submitted) }
    let!(:school_workforce_census_task_any_match) do
      submitted_claims.slice(0..9).each do |claim|
        create(:task, claim: claim, name: "census_subjects_taught", claim_verifier_match: :any)
      end
    end
    let!(:school_workforce_census_task_no_data) do
      create(:task, claim: submitted_claims.last, name: "census_subjects_taught", claim_verifier_match: nil)
    end

    describe ".grouped_census_subjects_taught_totals" do
      it "returns a Hash grouped by count" do
        expect(described_class.grouped_census_subjects_taught_totals).to be_an_instance_of(Hash)
        expect(described_class.grouped_census_subjects_taught_totals).to include("any" => 10, nil => 1)
      end
    end

    describe ".any_match_count" do
      it "returns the number of claims that had 'any' matching subjects" do
        expect(described_class.any_match_count).to eq 66.7
      end
    end

    describe ".no_data_census_subjects_taught_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(described_class.no_data_census_subjects_taught_count).to eq 6.7
      end
    end
  end

  context "with no submitted claims" do
    let(:submitted_claims) { create_list(:claim, 0, :submitted) }

    describe ".grouped_census_subjects_taught_totals" do
      it "returns an empty Hash" do
        expect(described_class.grouped_census_subjects_taught_totals).to be_an_instance_of(Hash)
        expect(described_class.grouped_census_subjects_taught_totals).to be_empty
      end
    end

    describe ".any_match_count" do
      it "returns the number of claims that had 'any' matching subjects" do
        expect(described_class.any_match_count).to eq 0.0
      end
    end

    describe ".no_data_census_subjects_taught_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(described_class.no_data_census_subjects_taught_count).to eq 0.0
      end
    end
  end
end

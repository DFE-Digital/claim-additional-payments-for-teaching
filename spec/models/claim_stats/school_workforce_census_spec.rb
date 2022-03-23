require "rails_helper"

RSpec.describe ClaimStats::SchoolWorkforceCensus do
  subject { ClaimStats::SchoolWorkforceCensus }

  context "when there are submitted claims" do
    let(:submitted_claims) { create_list(:claim, 15, :submitted) }
    let!(:school_workforce_census_task_any_match) do
      submitted_claims.slice(0..9).each do |claim|
        create(:task, claim: claim, name: "census_subjects_taught", claim_verifier_match: :any)
      end
    end
    let!(:school_workforce_census_task_no_match) do
      submitted_claims.slice(10..13).each do |claim|
        create(:task, claim: claim, name: "census_subjects_taught", claim_verifier_match: :none)
      end
    end
    let!(:school_workforce_census_task_no_data) do
      create(:task, claim: submitted_claims.last, name: "census_subjects_taught", claim_verifier_match: nil)
    end

    describe ".grouped_census_subjects_taught_totals" do
      it "returns a Hash grouped by count" do
        expect(subject.grouped_census_subjects_taught_totals).to be_an_instance_of(Hash)
        expect(subject.grouped_census_subjects_taught_totals).to include("none" => 4, "any" => 10, nil => 1)
      end
    end

    describe "not checked" do
      let(:submitted_claims) { create_list(:claim, 20, :submitted) }

      it "returns a count rounded to 1 dp of 25.0" do
        expect(subject.not_checked).to eq 25.0
      end
    end

    describe ".any_match_count" do
      it "returns the number of claims that had 'any' matching subjects" do
        expect(subject.any_match_count).to eq 66.7
      end
    end

    describe ".no_match_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(subject.no_match_count).to eq 26.7
      end
    end

    describe ".no_data_census_subjects_taught_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(subject.no_data_census_subjects_taught_count).to eq 6.7
      end
    end
  end

  context "with no submitted claims" do
    let(:submitted_claims) { create_list(:claim, 0, :submitted) }

    describe ".grouped_census_subjects_taught_totals" do
      it "returns an empty Hash" do
        expect(subject.grouped_census_subjects_taught_totals).to be_an_instance_of(Hash)
        expect(subject.grouped_census_subjects_taught_totals).to be_empty
      end
    end

    describe "not checked" do
      it "returns a count rounded to 1 dp of 0.0" do
        expect(subject.not_checked).to eq 0.0
      end
    end

    describe ".any_match_count" do
      it "returns the number of claims that had 'any' matching subjects" do
        expect(subject.any_match_count).to eq 0.0
      end
    end

    describe ".no_match_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(subject.no_match_count).to eq 0.0
      end
    end

    describe ".no_data_census_subjects_taught_count" do
      it "returns the number of claims that had 'no' matching subject" do
        expect(subject.no_data_census_subjects_taught_count).to eq 0.0
      end
    end
  end
end

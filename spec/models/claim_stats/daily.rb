require "rails_helper"

RSpec.describe ClaimStats::Daily do
  subject { ClaimStats::Daily }

  describe ".to_csv" do
    let!(:claims) do
      [EarlyCareerPayments, MathsAndPhysics, StudentLoans].collect do |policy|
        create(:claim, :approved, policy: policy)
      end
      ClaimStats.refresh
    end

    let(:expected_csv) do
      <<~CSV
        extract_date,policy,average_claim_submission_length,average_claim_decision_length,applications_started_total,applications_submitted_total,applications_rejected_total,applications_accepted_total,applications_started_daily,applications_submitted_daily,applications_rejected_daily,applications_accepted_daily
        #{Date.yesterday},early career payments,-0.0,0.0,1,1,0,1,0,0,0,0
        #{Date.yesterday},maths and physics,-0.0,0.0,1,1,0,1,0,0,0,0
        #{Date.yesterday},student loans,-0.0,0.0,1,1,0,1,0,0,0,0
      CSV
    end

    it "returns a csv with the correct stats" do
      expect(subject.to_csv).to eq(expected_csv)
    end
  end
end

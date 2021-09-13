require "rails_helper"

RSpec.describe ClaimStats::Daily do
  subject { ClaimStats::Daily }

  describe ".to_csv" do
    let(:started_yesterday) { [*1..3].sample }
    let(:started_previously) { [*1..3].sample }

    let(:rejected_yesterday) { [*1..3].sample }
    let(:rejected_previously) { [*1..3].sample }

    let(:approved_yesterday) { [*1..3].sample }
    let(:approved_previously) { [*1..3].sample }

    let(:yesterday) { Date.yesterday.noon }
    let(:previously) { yesterday - 1.day }

    let(:applications_started_total) {
      started_yesterday + started_previously + rejected_yesterday + rejected_previously + approved_yesterday + approved_previously
    }
    let(:applications_submitted_total) {
      rejected_previously + rejected_yesterday + approved_previously + approved_yesterday
    }
    let(:applications_rejected_total) {
      rejected_previously + rejected_yesterday
    }
    let(:applications_accepted_total) {
      approved_yesterday + approved_previously
    }
    let(:applications_started_daily) {
      started_yesterday + rejected_yesterday + approved_yesterday
    }
    let(:applications_submitted_daily) {
      rejected_yesterday + approved_yesterday
    }
    let(:applications_rejected_daily) {
      rejected_yesterday
    }
    let(:applications_accepted_daily) {
      approved_yesterday
    }

    before do
      [EarlyCareerPayments, MathsAndPhysics, StudentLoans].each do |policy|
        started_yesterday.times { create(:claim, policy: policy, created_at: yesterday) }
        started_previously.times { create(:claim, policy: policy, created_at: previously) }

        approved_yesterday.times { create(:claim, :approved, policy: policy, created_at: yesterday, submitted_at: yesterday + 60.seconds) }
        approved_previously.times { create(:claim, :approved, policy: policy, created_at: previously, submitted_at: previously + 60.seconds) }

        rejected_yesterday.times { create(:claim, :rejected, policy: policy, created_at: yesterday, submitted_at: yesterday + 60.seconds) }
        rejected_previously.times { create(:claim, :rejected, policy: policy, created_at: previously, submitted_at: previously + 60.seconds) }
      end

      allow_any_instance_of(Decision).to receive(:readonly?).and_return(false)

      Claim.all.each do |c|
        next unless c.decisions.any?

        c.decisions.first.update(created_at: c.created_at + 130.seconds)
      end

      ClaimStats.refresh
    end

    let(:expected_csv) do
      <<~CSV
        extract_date,policy,average_claim_submission_length,average_claim_decision_length,applications_started_total,applications_submitted_total,applications_rejected_total,applications_accepted_total,applications_started_daily,applications_submitted_daily,applications_rejected_daily,applications_accepted_daily
        #{yesterday.to_date},early career payments,60.0,70.0,#{applications_started_total},#{applications_submitted_total},#{applications_rejected_total},#{applications_accepted_total},#{applications_started_daily},#{applications_submitted_daily},#{applications_rejected_daily},#{applications_accepted_daily}
        #{yesterday.to_date},maths and physics,60.0,70.0,#{applications_started_total},#{applications_submitted_total},#{applications_rejected_total},#{applications_accepted_total},#{applications_started_daily},#{applications_submitted_daily},#{applications_rejected_daily},#{applications_accepted_daily}
        #{yesterday.to_date},student loans,60.0,70.0,#{applications_started_total},#{applications_submitted_total},#{applications_rejected_total},#{applications_accepted_total},#{applications_started_daily},#{applications_submitted_daily},#{applications_rejected_daily},#{applications_accepted_daily}
      CSV
    end

    it "returns a csv with the correct stats" do
      expect(subject.to_csv).to eq(expected_csv)
    end
  end
end

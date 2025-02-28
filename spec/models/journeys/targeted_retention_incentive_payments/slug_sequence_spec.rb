require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::SlugSequence do
  let(:journey_session) do
    create(:targeted_retention_incentive_payments_session, answers: {})
  end

  describe "#slugs" do
    context "eligibility slugs" do
      subject do
        described_class.new(journey_session).slugs.select do |slug|
          described_class::ELIGIBILITY_SLUGS.include?(slug)
        end
      end

      context "non tid, non trainee, non supply teacher, eligible degree subject" do
        it do
          is_expected.to match_array %w[
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            supply-teacher
            poor-performance
            qualification
            itt-year
            eligible-itt-subject
            teaching-subject-now
            check-your-answers-part-one
            eligibility-confirmed
          ]
        end
      end

      context "when a supply teacher" do
        before do
          journey_session.answers.assign_attributes(
            employed_as_supply_teacher: true
          )

          journey_session.save!
        end

        it do
          is_expected.to match_array %w[
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            supply-teacher
            entire-term-contract
            employed-directly
            poor-performance
            qualification
            itt-year
            eligible-itt-subject
            teaching-subject-now
            check-your-answers-part-one
            eligibility-confirmed
          ]
        end
      end
    end
  end
end

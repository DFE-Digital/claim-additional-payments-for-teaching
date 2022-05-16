require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::SubjectEligibility do
  let(:eligible_itt) { double("ITT", eligible?: true) }
  let(:ineligible_itt) { double("ITT", eligible?: false) }
  let(:eligible_degree) { double("Degree", eligible?: true) }
  let(:ineligible_degree) { double("Degree", eligible?: false) }
  let(:eligible_teaching) { double("TeachingMixture", teaching_eligible_subjects_fifty_percent_or_more?: true) }
  let(:ineligible_teaching) { double("TeachingMixture", teaching_eligible_subjects_fifty_percent_or_more?: false) }

  describe ".new" do
    specify { expect { described_class.new(itt_subject: eligible_itt, degree_subject: eligible_degree, teaching: nil) }.to raise_error("nil teaching") }
  end

  describe "#eligible?" do
    context "eligible" do
      context "eligible ITT and eligible degree and teaching eligible subjects 50% or more" do
        specify { expect(described_class.new(itt_subject: eligible_itt, degree_subject: eligible_degree, teaching: eligible_teaching)).to be_eligible }
      end

      context "eligible ITT but ineligible degree and teaching eligible subjects 50% or more" do
        specify { expect(described_class.new(itt_subject: eligible_itt, degree_subject: ineligible_degree, teaching: eligible_teaching)).to be_eligible }
      end

      context "ineligible ITT but eligible degree and teaching eligible subjects 50% or more" do
        specify { expect(described_class.new(itt_subject: ineligible_itt, degree_subject: eligible_degree, teaching: eligible_teaching)).to be_eligible }
      end
    end

    context "ineligible" do
      context "eligible ITT and eligible degree but teaching eligible subjects less than 50%" do
        specify { expect(described_class.new(itt_subject: eligible_itt, degree_subject: eligible_degree, teaching: ineligible_teaching)).to_not be_eligible }
      end

      context "ineligible ITT and ineligible degree but teaching eligible subjects 50% or more" do
        specify { expect(described_class.new(itt_subject: ineligible_itt, degree_subject: ineligible_degree, teaching: eligible_teaching)).to_not be_eligible }
      end

      context "no ITT" do
        specify { expect(described_class.new(itt_subject: nil, degree_subject: eligible_degree, teaching: eligible_teaching)).to_not be_eligible }
      end

      context "no degree" do
        specify { expect(described_class.new(itt_subject: eligible_itt, degree_subject: nil, teaching: eligible_teaching)).to_not be_eligible }
      end
    end
  end
end

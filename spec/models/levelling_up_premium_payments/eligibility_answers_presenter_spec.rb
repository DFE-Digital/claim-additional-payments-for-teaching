require "rails_helper"

RSpec.describe Policies::LevellingUpPremiumPayments::EligibilityAnswersPresenter, type: :model do
  it { expect(described_class).to be < Policies::EarlyCareerPayments::EligibilityAnswersPresenter }
end

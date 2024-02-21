require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::EligibilityAnswersPresenter, type: :model do
  it { expect(described_class).to be < Policies::EarlyCareerPayments::EligibilityAnswersPresenter }
end

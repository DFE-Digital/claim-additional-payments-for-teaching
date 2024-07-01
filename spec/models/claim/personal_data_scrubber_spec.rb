require "rails_helper"

RSpec.describe Claim::PersonalDataScrubber, type: :model do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::LevellingUpPremiumPayments
  )
end

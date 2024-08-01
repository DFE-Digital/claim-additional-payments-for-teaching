require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::EarlyCareerPayments
  )
end

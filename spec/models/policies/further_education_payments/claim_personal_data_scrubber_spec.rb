require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::FurtherEducationPayments
  )
end

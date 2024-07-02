require "rails_helper"

RSpec.describe Policies::StudentLoans::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::StudentLoans
  )
end

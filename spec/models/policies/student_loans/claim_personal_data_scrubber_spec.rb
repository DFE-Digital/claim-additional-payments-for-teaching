require "rails_helper"

RSpec.describe Policies::StudentLoans::ClaimPersonalDataScrubber do
  before { FeatureFlag.enable!(:schools_claims_approvable?) }

  it_behaves_like(
    "a claim personal data scrubber",
    Policies::StudentLoans
  )
end

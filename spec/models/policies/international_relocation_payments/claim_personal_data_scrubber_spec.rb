require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::ClaimPersonalDataScrubber do
  # FIXME RL: temp disabled until business decsion around whether TRN is
  # required in the payment claim matching has been resolved
  #  it_behaves_like(
  #    "a claim personal data scrubber",
  #    Policies::InternationalRelocationPayments
  #  )
end

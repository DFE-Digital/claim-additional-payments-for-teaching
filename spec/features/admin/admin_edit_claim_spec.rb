require "rails_helper"

RSpec.feature "Admin edits a claim with an award amount" do
  it_behaves_like "Admin Edit Claim Feature", Policies::TargetedRetentionIncentivePayments
  it_behaves_like "Admin Edit Claim Feature", Policies::EarlyCareerPayments
end

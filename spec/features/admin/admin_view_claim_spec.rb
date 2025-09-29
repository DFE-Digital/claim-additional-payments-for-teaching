require "rails_helper"

RSpec.feature "Admin view claim" do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  Policies
    .all
    .excluding(Policies::FurtherEducationPayments)
    .each { |policy| it_behaves_like "Admin View Claim Feature", policy }

  Policies
    .all
    .excluding(Policies::EarlyYearsPayments, Policies::FurtherEducationPayments)
    .each { |policy| it_behaves_like "Admin View Claim logged in with tid", policy }
end

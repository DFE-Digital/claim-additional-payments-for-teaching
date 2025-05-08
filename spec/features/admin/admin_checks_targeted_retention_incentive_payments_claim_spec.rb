require "rails_helper"

RSpec.feature "Admin checks a Levelling Up Premium Payments claim" do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  it_behaves_like "Admin Checks", Policies::TargetedRetentionIncentivePayments
end

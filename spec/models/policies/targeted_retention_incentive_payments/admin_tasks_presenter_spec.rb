require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::AdminTasksPresenter do
  it_behaves_like "ECP and Targeted Retention Incentive Combined Journey Admin Tasks Presenter", Policies::TargetedRetentionIncentivePayments
end

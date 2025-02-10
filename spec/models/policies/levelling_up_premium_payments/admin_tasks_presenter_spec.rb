require "rails_helper"

RSpec.describe Policies::LevellingUpPremiumPayments::AdminTasksPresenter do
  it_behaves_like "ECP and LUP Combined Journey Admin Tasks Presenter", Policies::LevellingUpPremiumPayments
end

require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::AdminTasksPresenter do
  it_behaves_like "ECP and LUP Combined Journey Admin Tasks Presenter", Policies::EarlyCareerPayments
end

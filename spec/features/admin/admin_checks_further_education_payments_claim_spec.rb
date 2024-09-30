require "rails_helper"

RSpec.feature "Admin checks an Further Education Payments claim" do
  it_behaves_like "Admin Checks", Policies::FurtherEducationPayments
end

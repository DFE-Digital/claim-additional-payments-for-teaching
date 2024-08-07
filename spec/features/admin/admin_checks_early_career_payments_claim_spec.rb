require "rails_helper"

RSpec.feature "Admin checks an Early Career Payments claim" do
  it_behaves_like "Admin Checks", Policies::EarlyCareerPayments
end

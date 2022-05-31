require "rails_helper"

RSpec.feature "Admin checks a Levelling Up Premium Payments claim" do
  it_behaves_like "Admin Checks for Early Career Payments and Levelling Up Premium Payments", LevellingUpPremiumPayments
end

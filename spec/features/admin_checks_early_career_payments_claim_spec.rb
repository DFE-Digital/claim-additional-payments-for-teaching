require "rails_helper"

RSpec.feature "Admin checks an Early Career Payments claim" do
  it_behaves_like "Admin Checks for Early Career Payments and Levelling Up Premium Payments", EarlyCareerPayments
end

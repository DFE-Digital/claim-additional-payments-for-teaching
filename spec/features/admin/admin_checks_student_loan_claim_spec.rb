require "rails_helper"

RSpec.feature "Admin checking a Student Loans claim" do
  it_behaves_like "Admin Checks", Policies::StudentLoans
end

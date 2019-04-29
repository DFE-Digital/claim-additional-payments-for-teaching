require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    visit root_path

    click_on "Agree and continue"

    expect(page).to have_text("Which academic year were you awarded qualified teacher status")
  end
end

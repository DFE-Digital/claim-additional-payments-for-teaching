require "rails_helper"

RSpec.feature "Admin claim filtering" do
  before { sign_in_as_service_operator }

  scenario "the service operator can filter claims by policy" do
    maths_and_physics_claims = create_list(:claim, 3, :submitted, policy: MathsAndPhysics)
    student_loan_claims = create_list(:claim, 2, :submitted, policy: StudentLoans)

    click_on "View claims"

    expect(page.find("table")).to have_content("Maths and Physics").exactly(3).times
    expect(page.find("table")).to have_content("Student Loans").exactly(2).times

    click_on "View claims"
    select "Maths and Physics", from: "policy"
    click_on "Go"

    maths_and_physics_claims.each do |c|
      expect(page).to have_content(c.reference)
    end

    student_loan_claims.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end
end

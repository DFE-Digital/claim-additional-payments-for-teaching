require "rails_helper"

RSpec.feature "Admin claim filtering" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

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

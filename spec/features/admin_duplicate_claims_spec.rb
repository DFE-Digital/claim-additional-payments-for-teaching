require "rails_helper"

RSpec.feature "Service operator can see potential duplicate claims" do
  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  scenario "they are shown other claims with matching details" do
    claim_to_approve = create(
      :claim,
      :submitted,
      teacher_reference_number: "0902344",
      national_insurance_number: "QQ891011C",
      email_address: "genghis.khan@mongol-empire.com",
      bank_account_number: "34682151",
      bank_sort_code: "972654",
      building_society_roll_number: "123456789/ABCD"
    )

    claim_with_matching_teacher_reference_number = create(:claim, :submitted, teacher_reference_number: claim_to_approve.teacher_reference_number)

    click_on "View claims"

    find("a[href='#{admin_claim_tasks_path(claim_to_approve)}']").click
    click_on "View full claim"

    expect(page).to have_content("Details in this claim match another Student Loans claim")
    expect(page).to have_content("Student Loans claim with matching details")

    expect(page).to have_content("#{claim_with_matching_teacher_reference_number.reference}\nTeacher reference number")
  end
end

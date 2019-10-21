require "rails_helper"

RSpec.feature "Admin checking duplicates" do
  let(:user_id) { "userid-345" }

  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user_id)
  end

  scenario "they are shown the possible duplicates" do
    claim_to_approve = create(
      :claim,
      :submitted,
      teacher_reference_number: "2136521",
    )

    claim_with_matching_teacher_reference_number = create(:claim, :submitted, teacher_reference_number: claim_to_approve.teacher_reference_number)

    click_on "View claims"

    find("a[href='#{admin_claim_path(claim_to_approve)}']").click

    expect(page).to have_content("Details in this claim match those in other claims")
    expect(page).to have_content("Claims with matching details")

    expect(page).to have_content("#{claim_with_matching_teacher_reference_number.reference}\nTeacher reference number")
  end
end

require "rails_helper"

RSpec.feature "Admin checking a claim missing a payroll gender" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "cannot approve a claim whilst the payroll gender is missing" do
    claim_missing_payroll_gender = create(:claim, :submitted, payroll_gender: :dont_know)

    click_on "View claims"
    find("a[href='#{admin_claim_path(claim_missing_payroll_gender)}']").click

    expect(page).to have_field("Approve", disabled: true)
    expect(page).to have_content(I18n.t("admin.unknown_payroll_gender_preventing_approval_message"))
  end
end

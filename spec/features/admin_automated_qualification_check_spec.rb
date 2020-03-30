require "rails_helper"

RSpec.feature "Admins automated qualification check" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "Service operators can upload and run automated DQT checks" do
    eligible_claim_with_matching_data = claim_from_example_dqt_report(:eligible_claim_with_matching_data)
    eligible_claim_with_non_matching_birthdate = claim_from_example_dqt_report(:eligible_claim_with_non_matching_birthdate)
    claim_without_dqt_record = claim_from_example_dqt_report(:claim_without_dqt_record)
    claim_with_ineligible_dqt_record = claim_from_example_dqt_report(:claim_with_ineligible_dqt_record)
    claim_with_decision = claim_from_example_dqt_report(:claim_with_decision)
    claim_with_qualification_task = claim_from_example_dqt_report(:claim_with_qualification_task)
    existing_qualification_task = claim_with_qualification_task.tasks.find_by!(name: "qualifications")

    click_on "View claims"
    click_on "Upload DQT report"

    attach_file("Upload a CSV file", example_dqt_report_csv.path)

    click_on "Upload"

    expect(page).to have_content "DQT report uploaded successfully. Automatically created checks for 1 claim out of 6 records."
    expect(eligible_claim_with_matching_data.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(eligible_claim_with_non_matching_birthdate.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_without_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_ineligible_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eq(existing_qualification_task)
  end
end

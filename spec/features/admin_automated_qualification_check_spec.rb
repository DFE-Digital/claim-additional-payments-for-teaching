require "rails_helper"

RSpec.feature "Admins automated qualification check" do
  before { sign_in_as_service_operator }

  scenario "Service operators can upload and run automated DQT checks" do
    claim_with_eligible_dqt_record = claim_from_example_dqt_report(:eligible_claim_with_matching_data)
    claim_without_dqt_record = claim_from_example_dqt_report(:claim_without_dqt_record)
    claim_with_ineligible_dqt_record = claim_from_example_dqt_report(:claim_with_ineligible_dqt_record)
    claim_with_decision = claim_from_example_dqt_report(:claim_with_decision)
    claim_with_qualification_task = claim_from_example_dqt_report(:claim_with_qualification_task)
    existing_qualification_task = claim_with_qualification_task.tasks.find_by!(name: "qualifications")

    click_on "View claims"
    click_on "Upload DQT report"

    attach_file("Upload a CSV file", example_dqt_report_csv.path)

    click_on "Upload"

    expect(page).to have_content "DQT report uploaded successfully. Automatically completed 1 task for 4 checked claims."
    expect(claim_with_eligible_dqt_record.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(claim_without_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_ineligible_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eq(existing_qualification_task)
  end
end

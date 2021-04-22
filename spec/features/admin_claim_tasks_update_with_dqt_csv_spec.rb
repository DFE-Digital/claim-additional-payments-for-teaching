require "rails_helper"

RSpec.feature "Admin claim tasks update with DQT CSV" do
  before { sign_in_as_service_operator }

  scenario "Service operators can upload and run automated DQT checks" do
    claim_with_eligible_dqt_record = claim_from_example_dqt_report(:eligible_claim_with_matching_data)
    claim_with_eligible_dqt_record_inc_hecos_code = claim_from_example_dqt_report(:eligible_claim_with_matching_data_and_hecos_code)
    eligible_claim_with_non_matching_birthdate = claim_from_example_dqt_report(:eligible_claim_with_non_matching_birthdate)
    eligible_claim_with_non_matching_surname = claim_from_example_dqt_report(:eligible_claim_with_non_matching_surname)
    claim_without_dqt_record = claim_from_example_dqt_report(:claim_without_dqt_record)
    claim_with_ineligible_dqt_record = claim_from_example_dqt_report(:claim_with_ineligible_dqt_record)
    claim_with_decision = claim_from_example_dqt_report(:claim_with_decision)
    claim_with_qualification_task = claim_from_example_dqt_report(:claim_with_qualification_task)
    existing_qualification_task = claim_with_qualification_task.tasks.find_by!(name: "qualifications")

    click_on "View claims"
    click_on "Upload DQT report"

    attach_file("Upload a CSV file", example_dqt_report_csv.path)

    click_on "Upload"
    expect(page).to have_content "DQT report uploaded successfully. Automatically completed 6 tasks for 7 checked claims."

    expect(claim_with_eligible_dqt_record.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(claim_with_eligible_dqt_record.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(claim_with_eligible_dqt_record_inc_hecos_code.tasks.find_by!(name: "qualifications").passed?).to eq(true)
    expect(claim_with_eligible_dqt_record_inc_hecos_code.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(eligible_claim_with_non_matching_birthdate.tasks.find_by(name: "qualifications").passed?).to eq(true)
    expect(eligible_claim_with_non_matching_birthdate.tasks.find_by(name: "identity_confirmation")).to be_nil

    expect(eligible_claim_with_non_matching_surname.tasks.find_by(name: "qualifications").passed?).to eq(true)
    expect(eligible_claim_with_non_matching_surname.tasks.find_by(name: "identity_confirmation")).to be_nil

    expect(claim_without_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_ineligible_dqt_record.tasks.find_by(name: "qualifications")).to be_nil
    expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil

    expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eq(existing_qualification_task)
  end
end

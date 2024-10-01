require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:college) { create(:school, :further_education, :fe_eligible) }
  let(:claim) { Claim.last }

  scenario "student loan data does not exist on submission" do
    when_further_education_journey_ready_to_submit

    perform_enqueued_jobs { click_on "Accept and send" }

    expect(claim.tasks.where(name: "student_loan_plan")).to be_empty

    sign_in_as_service_operator

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    within "li.student_loan_plan" do
      expect(page).to have_content "Incomplete"
    end
  end

  scenario "student loan data does exist on submission" do
    when_student_loan_data_exists
    when_further_education_journey_ready_to_submit

    perform_enqueued_jobs { click_on "Accept and send" }

    expect(claim.student_loan_plan).to eq "plan_1"

    sign_in_as_service_operator

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    expect(page).not_to have_content "Student loan plan"
  end
end

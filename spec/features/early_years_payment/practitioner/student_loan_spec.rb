require "rails_helper"

RSpec.feature "Early Years Payments Student Loan Plan" do
  include ActionView::Helpers::NumberHelper

  let(:claim) { Claim.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }
  let(:mail) { ActionMailer::Base.deliveries.last }

  scenario "student loan data does not exist on submission" do
    when_early_years_practitioner_claim_submitted

    expect(claim.tasks.where(name: "student_loan_plan")).to be_empty

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)
    within "li.student_loan_plan" do
      expect(page).to have_content "Incomplete"
    end
  end

  scenario "student loan data does exist on submission" do
    when_student_loan_data_exists
    when_early_years_practitioner_claim_submitted

    expect(claim.reload.student_loan_plan).to eq "plan_1"

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)
    expect(page).not_to have_content "Student loan plan"
  end
end

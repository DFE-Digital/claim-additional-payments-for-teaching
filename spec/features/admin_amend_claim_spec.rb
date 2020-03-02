require "rails_helper"

RSpec.feature "Admin amends a claim" do
  let(:claim) do
    create(:claim, :submitted,
      teacher_reference_number: "1234567",
      payroll_gender: :dont_know,
      date_of_birth: date_of_birth,
      student_loan_plan: :plan_1,
      bank_sort_code: "010203",
      bank_account_number: "47274828",
      building_society_roll_number: "RN 123456",)
  end
  let(:date_of_birth) { 25.years.ago.to_date }
  let(:service_operator) { create(:dfe_signin_user, given_name: "Jo", family_name: "Bloggs") }

  scenario "Service operator amends a claim" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, service_operator.dfe_sign_in_id)

    visit admin_claim_url(claim)

    click_on "Amend claim"

    new_date_of_birth = 30.years.ago.to_date

    fill_in "Teacher reference number", with: "7654321"
    select "Male", from: "Payroll gender"
    fill_in "Day", with: new_date_of_birth.day
    fill_in "Month", with: new_date_of_birth.month
    fill_in "Year", with: new_date_of_birth.year
    select "Plan 2", from: "Student loan repayment plan"
    fill_in "Bank sort code", with: "111213"
    fill_in "Bank account number", with: "18929492"
    fill_in "Building society roll number", with: "JF 838281"

    fill_in "Change notes", with: "This claimant got some of their details wrong and then contacted us"

    expect { click_on "Amend claim" }.to change { claim.reload.amendments.size }.by(1)

    amendment = claim.amendments.last
    expect(amendment.claim_changes).to eq({
      "teacher_reference_number" => ["1234567", "7654321"],
      "payroll_gender" => ["dont_know", "male"],
      "date_of_birth" => [date_of_birth, new_date_of_birth],
      "student_loan_plan" => ["plan_1", "plan_2"],
      "bank_sort_code" => ["010203", "111213"],
      "bank_account_number" => ["47274828", "18929492"],
      "building_society_roll_number" => ["RN 123456", "JF 838281"]
    })
    expect(amendment.notes).to eq("This claimant got some of their details wrong and then contacted us")
    expect(amendment.created_by).to eq(service_operator)

    expect(claim.reload.teacher_reference_number).to eq("7654321")
    expect(claim.payroll_gender).to eq("male")
    expect(claim.date_of_birth).to eq(new_date_of_birth)
    expect(claim.student_loan_plan).to eq("plan_2")
    expect(claim.bank_sort_code).to eq("111213")
    expect(claim.bank_account_number).to eq("18929492")
    expect(claim.building_society_roll_number).to eq("JF 838281")

    expect(current_url).to eq(admin_claim_url(claim))

    expect(page).to have_content("Teacher reference number\nchanged from 1234567 to 7654321")
    expect(page).to have_content("Payroll gender\nchanged from don’t know to male")
    expect(page).to have_content("Date of birth\nchanged from #{I18n.l(date_of_birth, format: :day_month_year)} to #{I18n.l(new_date_of_birth, format: :day_month_year)}")
    expect(page).to have_content("Student loan repayment plan\nchanged from Plan 1 to Plan 2")
    expect(page).to have_content("Bank sort code\nchanged from 010203 to 111213")
    expect(page).to have_content("Bank account number\nchanged from 47274828 to 18929492")
    expect(page).to have_content("Building society roll number\nchanged from RN 123456 to JF 838281")

    expect(page).to have_content("This claimant got some of their details wrong and then contacted us")
    expect(page).to have_content("by Jo Bloggs on #{I18n.l(Time.current)}")
  end

  scenario "Service operator cancels amending a claim" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, service_operator.dfe_sign_in_id)

    visit admin_claim_url(claim)

    click_on "Amend claim"

    fill_in "Teacher reference number", with: "7654321"

    expect { click_on "Cancel" }.not_to change { [claim.reload.amendments.size, claim.teacher_reference_number] }

    expect(current_url).to eq(admin_claim_url(claim))
  end

  # I would have written this as a request spec but there wasn’t an easy way
  # to do it because the message is split over various HTML tags.
  scenario "The amendments timeline can display an amendment that’s had its personal data removed" do
    create(:amendment, :personal_data_removed, claim: claim, claim_changes: {
      "teacher_reference_number" => ["7654321", "1234567"],
      "bank_account_number" => nil
    })

    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, service_operator.dfe_sign_in_id)

    visit admin_claim_url(claim)

    expect(page).to have_content("Teacher reference number\nchanged from 7654321 to 1234567")
    expect(page).to have_content("Bank account number\nchanged")
    expect(page).not_to have_content("Bank account number\nchanged from")
  end
end

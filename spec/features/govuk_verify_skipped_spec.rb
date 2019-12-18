require "rails_helper"

RSpec.feature "Bypassing GOV.UK Verify" do
  before { stub_geckoboard_dataset_update }

  scenario "Teacher can submit a claim without going through GOV.UK Verify" do
    @claim = start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching
    choose_leadership
    click_on "Continue"

    expect(page).to have_text("How we will use the information you provide")

    # At this point the teacher would normally go off to GOV.UK Verify for
    # identity verification. To simulate a user that has failed GOV.UK Verify,
    # we visit the URL where such users would be directed to after their GOV.UK
    # Verify attempt.

    visit claim_path(StudentLoans.routing_name, "name")

    expect(page).to have_text(I18n.t("questions.name"))
    fill_in "First name", with: "Dougie"
    fill_in "Middle names", with: "Cooper"
    fill_in "Last name", with: "Jones"
    click_on "Continue"

    @claim.reload
    expect(@claim.first_name).to eql("Dougie")
    expect(@claim.middle_name).to eql("Cooper")
    expect(@claim.surname).to eql("Jones")

    expect(page).to have_text(I18n.t("questions.address"))
    fill_in_address

    expect(@claim.reload.address_line_1).to eql("123 Main Street")
    expect(@claim.address_line_2).to eql("Downtown")
    expect(@claim.address_line_3).to eql("Twin Peaks")
    expect(@claim.address_line_4).to eql("Washington")
    expect(@claim.postcode).to eql("M1 7HL")

    expect(page).to have_text(I18n.t("questions.date_of_birth"))
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"

    expect(@claim.reload.date_of_birth).to eq(Date.new(1990, 7, 3))

    expect(page).to have_text(I18n.t("questions.payroll_gender"))
    choose "Male"
    click_on "Continue"

    expect(@claim.reload.payroll_gender).to eq("male")

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    answer_student_loan_plan_questions

    fill_in I18n.t("student_loans.questions.student_loan_amount"), with: "1100"
    click_on "Continue"

    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    freeze_time do
      perform_enqueued_jobs do
        expect {
          click_on "Confirm and send"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      expect(@claim.reload.submitted_at).to eq(Time.zone.now)
    end

    expect(page).to have_text("Claim submitted")
  end
end

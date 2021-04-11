require "rails_helper"

RSpec.feature "Teacher Early Career Payments claims" do
  scenario "Teacher makes claim for 'Early Career Payments' claim" do
    visit new_claim_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # TODO [PAGE 00] - Landing (start)

    # TODO - Investigate usage of new FormBuilder pattern & convert
    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # TODO [PAGE 02] - Which school do you teach at
    # TODO [PAGE 03] - Select the school you teach at
    # TODO [PAGE 04] - Are you currently employed as a supply teacher
    # TODO [PAGE 05] - Do you have a contract to teach at the same school
    # TODO [PAGE 06] - Are you employed directly by your school
    # TODO [PAGE 07] - Are you currently subject to action for poor performance
    # TODO [PAGE 08] - Are you currently subject to dsiciplinary action
    # TODO [PAGE 09] - Did you do a postgraduate ITT course or undergraduate ITT course
    # TODO [PAGE 10] - Which subject did you do your undergraduate ITT in
    # TODO [PAGE 11] - Which subject did you do your postgraduate ITT in
    # TODO [PAGE 12] - Do you teach maths now
    # TODO [PAGE 13] - In what academic year did you start your undergraduate ITT
    # TODO [PAGE 14] - In what academic year did you start your postgraduate ITT
    # TODO [PAGE 15] - Check your answers for eligibility
    # TODO [PAGE 16] - You are eligible for an early career payment
    # TODO [PAGE 20] - Personal Details
    # TODO [PAGE 21] - One Time Password
    # TODO [PAGE 22] - We have sent you reminders
    # TODO [PAGE 23] - How will we use the information you provide
    # TODO [PAGE 24] - Personal details
    # TODO [PAGE 25] - What is your address
    # TODO [PAGE 26] - Email address
    # TODO [PAGE 27] - Enter bank account details
    # TODO [PAGE 28] - What gender does your school's payroll system associate with you
    # TODO [PAGE 29] - What is your teacher reference number
    # TODO [PAGE 30] - Are you currently paying off your student loan
    # TODO [PAGE 31] - When you applied for your student loan where was your address
    # TODO [PAGE 32] - How many higher education courses did you take a student loan out for
    # TODO [PAGE 33] - When did the first year of your higher education course start
    # TODO [PAGE 34] - When did your higher education courses start
    # TODO [PAGE 35] - Did you take out a postgraduate masters loan on or after 1 August 2016
    # TODO [PAGE 36] - Did you take out a postgraduate doctoral loan on or after 1 August 2016

    # TODO [PAGE 37] - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")

    stub_geckoboard_dataset_update

    freeze_time do
      click_on "Confirm and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # TODO [PAGE 38] - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("Claim submitted")
    expect(page).to have_text(claim.reference)
    expect(page).to have_text(claim.email_address)
  end

  # Sad paths
  # TODO [PAGE 17] - This school is not eligible (sad path)
  # TODO [PAGE 18] - You are not eligible for an early career payment
  # TODO [PAGE 19] - You will be eligible for an early career payment in 2022
end

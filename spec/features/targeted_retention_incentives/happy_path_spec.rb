require "rails_helper"

RSpec.describe "Targeted retention incentives" do
  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments
    )
  end

  context "happy path" do
    context "with DfE Identity" do
    end

    context "without DfE Identity" do
      it "allows the user to submit a claim" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        choose "2023 to 2024"
        click_on "Continue"

        # eligible-itt-subject
        choose "Physics"
        click_on "Continue"

        # teaching-subject-now
        choose "Yes"
        click_on "Continue"

        expect(page).to have_content "Check your answers"

        expect(page).to have_summary_item(
          key: "Which school do you teach at?",
          value: school.name
        )

        expect(page).to have_summary_item(
          key: "Are you currently teaching as a qualified teacher?",
          value: "Yes"
        )

        expect(page).to have_summary_item(
          key: "Are you currently employed as a supply teacher?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Are you subject to any formal performance measures as a result " \
               "of continuous poor teaching standards?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Are you currently subject to disciplinary action?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Which route into teaching did you take?",
          value: "Postgraduate initial teacher training (ITT)"
        )

        expect(page).to have_summary_item(
          key: "In which academic year did you start your postgraduate initial "\
               "teacher training (ITT)?",
          value: "2023 to 2024"
        )

        expect(page).to have_summary_item(
          key: "Which subject did you do your postgraduate initial teacher " \
               "training (ITT) in?",
          value: "Physics"
        )

        expect(page).to have_summary_item(
          key: "Do you spend at least half of your contracted hours teaching " \
               "eligible subjects?",
          value: "Yes"
        )

        click_on "Continue"

        expect(page).to have_content(
          "You’re eligible for a targeted retention incentive payment"
        )

        expect(page).to have_text(
          "Based on what you told us, you can apply for a targeted retention " \
          "incentive payment of: £2,000"
        )

        click_on "Apply now"

        # information-provided
        expect(page).to have_text(
          "How we will use the information you provide"
        )
        click_on "Continue"

        # Personal details
        fill_in "First name", with: "Seymour"
        fill_in "Last name", with: "Skinner"

        fill_in "Day", with: "23"
        fill_in "Month", with: "10"
        fill_in "Year", with: "1953"

        fill_in "National Insurance number", with: "QQ123456C"
        click_on "Continue"

        click_on "Enter your address manually"

        fill_in "House number or name", with: "Test house"
        fill_in "Building and street", with: "Test street"
        fill_in "Town or city", with: "Test town"
        fill_in "County", with: "Testshire"
        fill_in "Postcode", with: "TE57 1NG"
        click_on "Continue"

        fill_in "Email address", with: "test@example.com"
        click_on "Continue"

        mail = ActionMailer::Base.deliveries.last
        otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

        fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent

        # provide-mobile-number
        choose "No"
        click_on "Continue"

        fill_in "Name on your account", with: "Seymour Skinner"
        fill_in "Sort code", with: "000000"
        fill_in "Account number", with: "00000000"
        click_on "Continue"

        # gender
        choose "Male"
        click_on "Continue"

        # trn
        fill_in "What is your teacher reference number (TRN)?", with: "1234567"
        click_on "Continue"

        # check-your-answers
        expect(page).to have_content(
          "Check your answers before sending your application"
        )

        click_on "Accept and send"

        expect(page).to have_content(
          "You applied for a targeted retention incentive payment"
        )
      end
    end

    context "When a supply teacher" do
      it "allows the user to sbumit a claim" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "Yes"
        click_on "Continue"

        # entire-term-contract
        choose "Yes"
        click_on "Continue"

        # employed-directly
        choose "Yes"
        click_on "Continue"

        # poor-performance
        all("input[type=radio][value='no']").each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        choose "2023 to 2024"
        click_on "Continue"

        # eligible-itt-subject
        choose "Physics"
        click_on "Continue"

        choose "Yes"
        click_on "Continue"

        expect(page).to have_content "Check your answers"
      end
    end
  end
end

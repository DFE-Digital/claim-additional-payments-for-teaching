require "rails_helper"

RSpec.feature "Bank account validation on claim journey", :with_hmrc_bank_validation_enabled do
  before do
    FeatureFlag.enable!(:tri_only_journey)
  end
  let(:journey_session) do
    Journeys::TargetedRetentionIncentivePayments::Session.order(:created_at).last
  end
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments_only) }
  let!(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
  let(:bank_name) { "Jo Bloggs" }
  let(:sort_code) { "123456" }
  let(:account_number) { "87654321" }

  def get_to_bank_details_page
    visit new_claim_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    choose "No"
    click_on "Continue"

    # - Poor performance
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you complete your postgraduate ITT?
    choose "2020 to 2021"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    click_on("Continue")

    click_on("Apply now")

    # - How will we use the information you provide
    click_on "Continue"

    # - Personal details
    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"
    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    # - What is your home address
    click_on(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    # - Email address
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

    # - One time password
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]

    # - clear and enter correct OTP
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    choose "No"
    click_on "Continue"
  end

  context "HMRC API returns a 200 response", :with_stubbed_hmrc_client do
    context "HMRC API passes bank details match" do
      let(:hmrc_response) { double(name_match?: true, sort_code_correct?: true, code: 200, body: "Test response") }

      scenario "redirects user to next page" do
        allow(hmrc_response).to receive(:success?).and_return(true)
        allow(hmrc_response).to receive(:account_exists?).and_return(true)

        get_to_bank_details_page

        # - Enter bank account details
        fill_in "Name on your account", with: bank_name
        fill_in "Sort code", with: sort_code
        fill_in "Account number", with: "1111111" # Invalid number
        click_on "Continue"

        expect(page).to have_text "Account number must be 8 digits"
        fill_in "Account number", with: account_number
        click_on "Continue"

        expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))

        journey_session.reload
        answers = journey_session.answers
        expect(answers.hmrc_bank_validation_succeeded?).to eq true
        expect(answers.hmrc_bank_validation_responses).not_to be_empty

        # - HMRC API fails bank details match"
        click_on "Back"

        allow(hmrc_response).to receive(:success?).and_return(false)
        allow(hmrc_response).to receive(:account_exists?).and_return(false)

        # shows an error and allows through after three attempts

        # - Enter bank account details
        fill_in "Name on your account", with: bank_name
        fill_in "Sort code", with: sort_code
        fill_in "Account number", with: account_number
        click_on "Continue"

        expect(page).to have_text "Enter the account number associated with the name on the account and/or sort code"
        click_on "Continue"

        expect(page).to have_text "Enter the account number associated with the name on the account and/or sort code"
        click_on "Continue"

        # Third attempt succeeds.
        expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))

        journey_session.reload
        answers = journey_session.answers
        expect(answers.hmrc_bank_validation_succeeded?).not_to be true
        expect(answers.hmrc_bank_validation_responses).not_to be_empty
      end
    end
  end

  context "HMRC API returns an error", :with_failing_hmrc_bank_validation do
    scenario "allows user through" do
      get_to_bank_details_page

      # - Enter bank account details
      fill_in "Name on your account", with: bank_name
      fill_in "Sort code", with: sort_code
      fill_in "Account number", with: account_number

      click_on "Continue"

      expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))

      journey_session.reload
      answers = journey_session.answers
      expect(answers.hmrc_bank_validation_succeeded?).not_to be true
    end
  end
end

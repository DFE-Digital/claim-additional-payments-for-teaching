require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims" do
  context "with a mobile number provided" do
    before do
      allow(NotifySmsMessage).to receive(:new).with(
        phone_number: "07123456789",
        template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
        personalisation: {
          otp: otp_code
        }
      ).and_return(notify)
      allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: otp_code))
      allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
    end

    let(:otp_code) { "330547" }
    let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }
    let(:personal_details_attributes) do
      {
        first_name: "Shona",
        surname: "Riveria",
        date_of_birth: Date.new(1987, 11, 30),
        national_insurance_number: "AG749900B",
        address_line_1: "105A",
        address_line_2: "Cheapstow Road",
        address_line_3: "Cheapstow",
        address_line_4: "Bristol",
        postcode: "BS1 4BS",
        email_address: "s.riveria80s@example.com",
        provide_mobile_number: true,
        email_verified: true
      }
    end

    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.update!(personal_details_attributes)
      claim
    end

    scenario "Teacher makes claim for 'Early-Career Payments' claim", js: true do
      visit claim_path(claim.policy.routing_name, "mobile-number")

      expect(claim.reload.provide_mobile_number).to eql true

      # - Mobile number
      expect(page).to have_text(I18n.t("questions.mobile_number"))

      fill_in "claim_mobile_number", with: "07123456789"
      click_on "Continue"

      expect(claim.reload.mobile_number).to eql("07123456789")

      # - Mobile number one-time password
      expect(page).to have_text("Password verification")
      expect(page).to have_text("Enter the 6-digit password")
      expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

      fill_in "claim_one_time_password", with: otp_code
      click_on "Confirm"

      # Payment to Bank or Building Society
      expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

      choose "Personal bank account"
      click_on "Continue"

      expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

      # - Enter bank account details
      expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
      expect(page).not_to have_text("Building society roll number")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")

      # - What gender does your school's payroll system associate with you
      expect(page).to have_text(I18n.t("questions.payroll_gender"))

      choose "Female"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("female")

      # - What is your teacher reference number
      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      # - Are you currently paying off your student loan
      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.has_student_loan).to eql true

      # - When you applied for your student loan where was your address
      expect(page).to have_text(I18n.t("questions.student_loan_country"))

      choose "England"
      click_on "Continue"

      expect(claim.reload.student_loan_country).to eql("england")

      # - How many higher education courses did you take a student loan out for
      expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

      choose "1"
      click_on "Continue"

      expect(claim.reload.student_loan_courses).to eql("one_course")

      # - When did the first year of your higher education course start
      expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

      choose "Before 1 September 2012"
      click_on "Continue"

      expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      # - Are you currently paying off your masters/doctoral loan
      expect(page).not_to have_text(I18n.t("questions.has_masters_and_or_doctoral_loan"))
      expect(claim.reload.has_masters_doctoral_loan).to be_nil

      # - Did you take out a postgraduate masters loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_masters_loan).to eql true

      # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_doctoral_loan).to eql true

      # - Check your answers before sending your application
      expect(page).to have_text("Check your answers before sending your application")
      expect(page).not_to have_text("Eligibility details")
      %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
        expect(page).to have_text section_heading
      end

      within(".govuk-summary-list:nth-of-type(3)") do
        expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))
        expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
      end

      stub_geckoboard_dataset_update

      freeze_time do
        click_on "Accept and send"

        expect(claim.reload.submitted_at).to eq(Time.zone.now)
      end

      # - Application complete (make sure its Word for Word and styling matches)
      expect(page).to have_text("Application complete")
      expect(page).to have_text("What happens next")
      expect(page).to have_text("Set a reminder for when your next application window opens")
      expect(page).to have_text("What did you think of this service?")
      expect(page).to have_text(claim.reference)
    end
  end
end

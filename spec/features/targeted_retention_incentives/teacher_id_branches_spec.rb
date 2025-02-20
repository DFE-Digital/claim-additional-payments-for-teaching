require "rails_helper"

RSpec.describe "Targeted retention incentives with Teacher ID" do
  include OmniauthMockHelper

  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments,
      teacher_id_enabled: true
    )
  end

  after do
    set_mock_auth(nil)
  end

  it "uses information from teacher id and TPS to speed up the journey" do
    la = create(:local_authority)

    # Presence of a matching TPS record triggers the slug sequence to show
    # the "correct-school"
    tps_record = create(
      :teachers_pensions_service,
      school_urn: 123456,
      teacher_reference_number: 1234567,
      end_date: 1.day.from_now,
      la_urn: la.code
    )

    school = create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      name: "Springfield Elementary School",
      establishment_number: tps_record.school_urn,
      local_authority: la
    )

    set_mock_auth(
      "1234567",
      {
        date_of_birth: "1953-10-23",
        nino: "QQ123456C",
        given_name: "Seymour",
        family_name: "Skinner",
        email: "seymoure.skinner@springfield-elementary.edu",
        email_verified: true,
      },
      phone_number: "07700900000"
    )

    stub_qualified_teaching_statuses_show(
      trn: "1234567",
      params: { birthdate: "1953-10-23", nino: "QQ123456C" },
      body: {
        qualified_teacher_status: {
          qts_date: "2023-07-01"
        },
        initial_teacher_training: {
          subject1: "physics",
          subject1_code: "F300"
        }
      }
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue with DfE Identity"

    # Teacher details page
    expect(page).to have_content("You must check that all details are correct")

    expect(page).to have_summary_item(
      key: "Name",
      value: "Seymour Skinner"
    )

    expect(page).to have_summary_item(
      key: "Date of birth",
      value: "23 October 1953"
    )

    expect(page).to have_summary_item(
      key: "Teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "National Insurance number",
      value: "QQ123456C"
    )

    choose "Yes"
    click_on "Continue"

    # correct-school
    choose "Springfield Elementary School"
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    choose "Yes"
    click_on "Continue"

    # supply-teacher
    choose "No"
    click_on "Continue"

    # poor-performance
    all(".govuk-radios__label").select { |it| it.text == "No" }.each(&:click)
    click_on "Continue"

    # Qualification details confirmation page (instead of qualification questions)
    expect(page).to have_content("Check and confirm your qualification details")

    expect(page).to have_summary_item(
      key: "Teacher route taken",
      value: "Undergraduate initial teacher training (ITT)"
    )

    expect(page).to have_summary_item(
      key: "Academic year you completed your undergraduate initial teacher " \
           "training (ITT)",
      value: "2022/2023"
    )

    # Not showing degree subjects as eligible itt subject is not
    # "none_of_the_above"

    expect(page).to have_summary_item(
      key: "Subject you did your undergraduate initial teacher training (ITT) in",
      value: "Physics"
    )

    # confirm qualification details
    choose "Yes"
    click_on "Continue"

    # Skip qualification, itt-year, and eligible-itt-subject questions

    # teaching-subject-now
    expect(page).to have_content("Do you spend at least half of your contracted hours teaching eligible subjects?")
    choose "Yes"
    click_on "Continue"

    # check-your-answers-part-one
    expect(page).to have_content("Check your answers")

    click_on "Continue"

    # eligibility-confirmed
    expect(page).to have_content(
      "You’re eligible for a targeted retention incentive payment"
    )
    click_on "Apply now"

    # information-provided
    expect(page).to have_content("How we will use the information you provide")
    click_on "Continue"

    # Personal details page should be skipped since TID provided all details

    # Postcode search
    expect(page).to have_content("What is your home address?")
    click_on "Enter your address manually"

    # Address
    fill_in "House number or name", with: "42"
    fill_in "Building and street", with: "Computation Avenue"
    fill_in "Town or city", with: "Cambridge"
    fill_in "County", with: "Cambridgeshire"
    fill_in "Postcode", with: "CB2 1TN"
    click_on "Continue"

    # select-email
    expect(page).to have_content("Which email address should we use to contact you?")
    choose "seymoure.skinner@springfield-elementary.edu"
    click_on "Continue"

    # select-mobile
    expect(page).to have_content("Which mobile number should we use to contact you?")
    choose "07700900000"
    click_on "Continue"

    # personal-bank-account
    fill_in "Name on your account", with: "Seymour Skinner"
    fill_in "Sort code", with: "000000"
    fill_in "Account number", with: "12345678"
    click_on "Continue"

    # gender
    choose "Male"
    click_on "Continue"

    # teacher-reference-number should be skipped since it's from TID

    # check-your-answers
    expect(page).to have_content("Check your answers before sending your application")

    click_on "Accept and send"

    # Confirmation page
    expect(page).to have_content("You applied for a targeted retention incentive payment")

    # Verify claim details
    # We can't check the content on check your answers as information from TID
    # isn't shown
    claim = Claim.by_policy(Policies::TargetedRetentionIncentivePayments).order(created_at: :desc).first
    expect(claim.first_name).to eq("Seymour")
    expect(claim.surname).to eq("Skinner")
    expect(claim.date_of_birth).to eq(Date.new(1953, 10, 23))
    expect(claim.national_insurance_number).to eq("QQ123456C")
    expect(claim.email_address).to eq("seymoure.skinner@springfield-elementary.edu")
    expect(claim.mobile_number).to eq("07700900000")
    expect(claim.logged_in_with_tid).to be true

    eligibility = claim.eligibility
    expect(eligibility.teacher_reference_number).to eq("1234567")
    expect(eligibility.current_school).to eq(school)
    expect(eligibility.eligible_itt_subject).to eq("physics")
    expect(eligibility.qualification).to eq("undergraduate_itt")
    expect(eligibility.itt_academic_year).to eq(AcademicYear.new(2022))
  end
end

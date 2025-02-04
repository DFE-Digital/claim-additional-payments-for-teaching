require "rails_helper"

describe "teacher route: completing the form" do
  include GetATeacherRelocationPayment::StepHelpers

  let(:journey_configuration) do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:contract_start_date) do
    Policies::InternationalRelocationPayments::PolicyEligibilityChecker
      .earliest_eligible_contract_start_date
  end

  let(:entry_date) do
    contract_start_date - 1.week
  end

  let(:school) do
    create(:school)
  end

  before do
    journey_configuration
  end

  describe "navigating forward", flaky: true do
    before do
      when_i_start_the_form
      and_i_complete_application_route_question_with(
        option: "I am employed as a teacher in a school in England"
      )
      and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
      and_i_complete_the_current_school_step(school)
      and_i_complete_the_headteacher_step
      and_i_complete_the_contract_details_step_with(option: "Yes")
      and_i_complete_the_contract_start_date_step_with(
        date: contract_start_date
      )
      and_i_complete_the_subject_step_with(option: "Physics")
      and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
      and_i_complete_the_entry_date_page_with(date: entry_date)
      then_the_check_your_answers_part_one_page_shows_my_answers
      and_i_dont_change_my_answers
    end

    context "with postcode search" do
      it "submits an application" do
        and_i_complete_the_nationality_step_with(option: "Australian")
        and_i_complete_the_passport_number_step_with(options: "123456789")
        and_i_complete_the_personal_details_step
        and_i_complete_the_postcode_step
        and_i_complete_the_email_address_step
        and_i_dont_provide_my_mobile_number
        and_i_provide_my_personal_bank_details
        and_i_complete_the_payroll_gender_step
        then_the_check_your_answers_part_page_shows_my_answers(school)
        and_i_submit_the_application
        then_the_application_is_submitted_successfully
      end
    end

    context "without postcode search" do
      it "submits an application", js: true do
        and_i_complete_the_nationality_step_with(option: "Australian")
        and_i_complete_the_passport_number_step_with(options: "123456789")
        and_i_complete_the_personal_details_step
        and_i_complete_the_manual_address_step
        and_i_complete_the_email_address_step
        and_i_dont_provide_my_mobile_number
        and_i_provide_my_personal_bank_details
        and_i_complete_the_payroll_gender_step
        then_the_check_your_answers_part_page_shows_my_answers(school)
        and_i_submit_the_application
        then_the_application_is_submitted_successfully
      end
    end

    context "with mobile verification" do
      it "submits an application" do
        and_i_complete_the_nationality_step_with(option: "Australian")
        and_i_complete_the_passport_number_step_with(options: "123456789")
        and_i_complete_the_personal_details_step
        and_i_complete_the_manual_address_step
        and_i_complete_the_email_address_step
        and_i_provide_my_mobile_number
        and_i_provide_my_personal_bank_details
        and_i_complete_the_payroll_gender_step
        then_the_check_your_answers_part_page_shows_my_answers(school, mobile_number: true)
        and_i_submit_the_application
        then_the_application_is_submitted_successfully
      end
    end
  end

  def then_the_check_your_answers_part_one_page_shows_my_answers
    assert_on_check_your_answers_part_one_page!

    expect(page).to have_text(
      "What is your employment status? I am employed as a teacher in a school in England"
    )

    expect(page).to have_text(
      "Are you employed by an English state secondary school? Yes"
    )

    expect(page).to have_text(
      "Which school are you currently employed to teach at? #{school.name}"
    )

    expect(page).to have_text(
      "Enter the name of the headteacher of the school where you are employed as a teacher Seymour Skinner"
    )

    expect(page).to have_text(
      "Are you employed on a contract lasting at least one year? Yes"
    )

    expect(page).to have_text(
      "Enter the start date of your contract #{I18n.l(contract_start_date)}"
    )

    expect(page).to have_text(
      "What subject are you employed to teach at your school? Physics"
    )

    expect(page).to have_text(
      "Select the visa you used to move to England British National (Overseas) visa"
    )

    expect(page).to have_text(
      "Enter the date you moved to England to start your teaching job #{I18n.l(entry_date)}"
    )
  end

  def then_the_check_your_answers_part_page_shows_my_answers(school, mobile_number: false, building_society: false)
    expect(page).to have_text(
      "What is your full name? Walter Seymour Skinner"
    )

    expect(page).to have_text(
      "What is your date of birth? 12 July 1945"
    )

    expect(page).to have_text(
      "What is your National Insurance number? QQ123456C"
    )

    expect(page).to have_text(
      "What is your address? Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    )

    expect(page).to have_text(
      "Email address seymour.skinner@springfieldelementary.edu"
    )

    expect(page).to have_text("Select your nationality Australian")

    expect(page).to have_text(
      "Enter your passport number, as it appears on your passport 123456789"
    )

    if mobile_number
      expect(page).to have_text("Mobile number 01234567890")
    else
      expect(page).to have_text(
        "Would you like to provide your mobile number? No"
      )
    end

    expect(page).to have_text("Name on bank account Walter Skinner")
    expect(page).to have_text("Bank sort code 123456")
    expect(page).to have_text("Bank account number 12345678")

    expect(page).to have_text(
      "How is your gender recorded on your school’s payroll system? Male"
    )
  end
end

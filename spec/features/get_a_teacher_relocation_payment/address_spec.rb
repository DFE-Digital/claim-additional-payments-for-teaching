require "rails_helper"

RSpec.feature "International relocation payments address", slow: true do
  include GetATeacherRelocationPayment::StepHelpers

  it_behaves_like(
    "an address journey",
    change_address_link: "Change what is your address?",
    check_answers_heading: "Check your answers before sending your application"
  )

  def complete_journey_upto_postcode_search
    create(:journey_configuration, :get_a_teacher_relocation_payment)

    contract_start_date = Policies::InternationalRelocationPayments::PolicyEligibilityChecker
      .earliest_eligible_contract_start_date
    entry_date = contract_start_date - 1.week
    school = create(:school)

    when_i_start_the_form
    and_i_complete_the_previous_irp_payment_question_with(option: "Yes")
    and_i_complete_application_route_question_with(
      option: "I am employed as a teacher in a school in England"
    )
    and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
    and_i_complete_the_current_school_step(school)
    and_i_complete_the_headteacher_step
    and_i_complete_the_contract_details_step_with(option: "Yes")
    and_i_complete_the_contract_start_date_step_with(date: contract_start_date)
    and_i_complete_the_subject_step_with(option: "Physics")
    and_i_complete_changed_workplace_or_new_contract_with(option: "No")
    and_i_complete_breaks_in_employment_with(option: "Yes")
    and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
    and_i_complete_the_entry_date_page_with(date: entry_date)
    and_i_dont_change_my_answers
    and_i_complete_the_information_provided_step
    and_i_complete_the_nationality_step_with(option: "Australian")
    and_i_complete_the_passport_number_step_with(options: "123456789")
    and_i_complete_the_personal_details_step

    expect(page).to have_content "What is your home address?"
  end

  def complete_journey_from_address_to_check_answers
    and_i_complete_the_email_address_step
    and_i_dont_provide_my_mobile_number
    and_i_provide_my_personal_bank_details
    and_i_complete_the_payroll_gender_step

    expect(page).to have_content "Check your answers before sending your application"
  end
end

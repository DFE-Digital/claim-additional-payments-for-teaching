require "rails_helper"

describe "teacher route: completing the form" do
  include GetATeacherRelocationPayment::StepHelpers

  let(:journey_configuration) do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:contract_start_date) do
    Date.tomorrow
  end

  let(:entry_date) do
    contract_start_date - 1.week
  end

  before do
    journey_configuration
  end

  describe "navigating forward" do
    it "submits an application" do
      when_i_start_the_form
      and_i_complete_application_route_question_with(
        option: "I am employed as a teacher in a school in England"
      )
      and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
      and_i_complete_the_contract_details_step_with(option: "Yes")
      and_i_complete_the_contract_start_date_step_with(
        date: contract_start_date
      )
      and_i_complete_the_subject_step_with(option: "Physics")
      and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
      and_i_complete_the_entry_date_page_with(date: entry_date)
      then_the_check_your_answers_part_one_page_shows_my_answers
      and_i_dont_change_my_answers
      and_the_personal_details_section_has_been_temporarily_stubbed
      and_i_submit_the_application
      then_the_application_is_submitted_successfully
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
      "Are you employed on a contract lasting at least one year? Yes"
    )

    expect(page).to have_text(
      "Enter the start date of your contract #{contract_start_date.strftime("%d-%m-%Y")}"
    )

    expect(page).to have_text(
      "What subject are you employed to teach at your school? Physics"
    )

    expect(page).to have_text(
      "Select the visa you used to move to England British National (Overseas) visa"
    )

    expect(page).to have_text(
      "Enter the date you moved to England to start your teaching job #{entry_date.strftime("%d-%m-%Y")}"
    )
  end
end

require "rails_helper"

describe "teacher route: completing the form" do
  include GetATeacherRelocationPayment::StepHelpers

  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  describe "navigating forward" do
    it "submits an application" do
      when_i_start_the_form
      and_i_complete_application_route_question_with(
        option: "I am employed as a teacher in a school in England"
      )
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
  end
end

require "rails_helper"

describe "ineligible route: completing the form" do
  include GetATeacherRelocationPayment::StepHelpers

  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  describe "navigating forward" do
    context "ineligible - application route" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(option: "Other")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - non state funded school" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "No")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - trainee details" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am enrolled on a salaried teacher training course in England"
        )
        and_i_complete_the_trainee_details_step_with(option: "No")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - contract details" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_contract_details_step_with(option: "No")
        then_i_see_the_ineligible_page
      end
    end
  end

  def then_i_see_the_ineligible_page
    expect(page).to have_content(
      "We’re sorry, but you are not currently eligible for the international relocation payment"
    )
  end
end

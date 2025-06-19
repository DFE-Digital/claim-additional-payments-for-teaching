require "rails_helper"

RSpec.describe "ineligible route: completing the form" do
  include GetATeacherRelocationPayment::StepHelpers

  let(:journey_configuration) do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:contract_start_date) do
    Policies::InternationalRelocationPayments::PolicyEligibilityChecker
      .earliest_eligible_contract_start_date
  end

  before do
    journey_configuration
  end

  describe "navigating forward" do
    context "ineligible - application route" do
      context "when choosing other" do
        it "shows the ineligible page" do
          when_i_start_the_form
          and_i_complete_application_route_question_with(option: "Other")
          then_i_see_the_ineligible_page
        end
      end

      context "when choosing trainee" do
        it "shows the ineligible page" do
          when_i_start_the_form
          and_i_complete_application_route_question_with(
            option: "I am enrolled on a salaried teacher training course in England"
          )
          then_i_see_the_ineligible_page
        end
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

    context "ineligible - school-choice" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_current_school_step(create(:school, phase: :primary))
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
        and_i_complete_the_current_school_step(create(:school, phase: :secondary))
        and_i_complete_the_headteacher_step
        and_i_complete_the_contract_details_step_with(option: "No")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - contract start date" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_current_school_step(create(:school, phase: :secondary))
        and_i_complete_the_headteacher_step
        and_i_complete_the_contract_details_step_with(option: "Yes")
        and_i_complete_the_contract_start_date_step_with(
          date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker
          .earliest_eligible_contract_start_date - 1.day
        )
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - subject" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_current_school_step(create(:school, phase: :secondary))
        and_i_complete_the_headteacher_step
        and_i_complete_the_contract_details_step_with(option: "Yes")
        and_i_complete_the_contract_start_date_step_with(
          date: contract_start_date
        )
        and_i_complete_the_subject_step_with(option: "Other")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - visa" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_current_school_step(create(:school, phase: :secondary))
        and_i_complete_the_headteacher_step
        and_i_complete_the_contract_details_step_with(option: "Yes")
        and_i_complete_the_contract_start_date_step_with(
          date: contract_start_date
        )
        and_i_complete_the_subject_step_with(option: "Physics")
        and_i_complete_changed_workplace_or_new_contract_with(option: "Yes")
        and_i_complete_breaks_in_employment_with(option: "Yes")
        and_i_complete_the_visa_screen_with(option: "Other")
        then_i_see_the_ineligible_page
      end
    end

    context "ineligible - entry date" do
      it "shows the ineligible page" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(
          option: "I am employed as a teacher in a school in England"
        )
        and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
        and_i_complete_the_current_school_step(create(:school, phase: :secondary))
        and_i_complete_the_headteacher_step
        and_i_complete_the_contract_details_step_with(option: "Yes")
        and_i_complete_the_contract_start_date_step_with(
          date: contract_start_date
        )
        and_i_complete_the_subject_step_with(option: "Physics")
        and_i_complete_changed_workplace_or_new_contract_with(option: "Yes")
        and_i_complete_breaks_in_employment_with(option: "Yes")
        and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
        and_i_complete_the_entry_date_page_with(date: contract_start_date - 4.months)
        then_i_see_the_ineligible_page
      end
    end
  end

  def then_i_see_the_ineligible_page
    expect(page).to have_content(
      "You are not currently eligible for the international relocation payment."
    )
  end
end

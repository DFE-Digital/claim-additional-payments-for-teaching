require "rails_helper"

describe "teacher route: completing the form" do
  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  describe "navigating forward" do
    context "eligible users" do
      it "submits an application" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(option: "teacher")
        and_i_complete_the_state_school_question
        and_i_complete_the_contract_details_question
        and_i_enter_my_contract_start_date
        and_i_select_my_subject("teacher")
        and_i_select_my_visa_type
        and_i_enter_my_entry_date("teacher")
        and_i_enter_my_personal_details
        and_i_enter_my_employment_details
        and_i_submit_the_application

        then_the_application_is_submitted_successfully
      end
    end

    context "non-eligible users" do
      it "does not allow the user to continue the journey" do
        when_i_start_the_form
        and_i_complete_application_route_question_with(option: "teacher")
        and_i_complete_the_state_school_question
        and_i_complete_the_contract_details_question
        and_i_enter_an_invalid_date

        expect(page).to have_text("Enter your contract start date")
      end
    end
  end

  describe "navigating backwards" do
    it "allows the user to navigate back to the previous pages" do
      when_i_start_the_form
      and_i_complete_application_route_question_with(option: "teacher")
      and_i_complete_the_state_school_question
      and_i_complete_the_contract_details_question
      and_i_enter_my_contract_start_date
      and_i_select_my_subject("teacher")
      and_i_select_my_visa_type
      and_i_enter_my_entry_date("teacher")
      and_i_enter_my_personal_details

      # We're now on the employment details page
      # We start going backwards
      when_i_click_the_back_link
      assert_i_am_in_the_personal_details_question

      when_i_click_the_back_link
      assert_i_am_in_the_entry_date_question("teacher")

      when_i_click_the_back_link
      assert_i_am_in_the_visa_type_question

      when_i_click_the_back_link
      assert_i_am_in_the_subject_question("teacher")

      when_i_click_the_back_link
      assert_i_am_in_the_contract_start_date_question

      when_i_click_the_back_link
      assert_i_am_on_the_contract_details_question

      when_i_click_the_back_link
      assert_i_am_in_the_state_school_question

      when_i_click_the_back_link
      assert_i_am_in_the_application_route_question
    end
  end

  def then_the_application_is_submitted_successfully
    expect(page).to have_text("You have successfully submitted")
    expect(Application.count).to eq(1)
    expect(Applicant.count).to eq(1)
    expect(Address.count).to eq(2)
    expect(ApplicationProgress.count).to eq(1)
    expect(School.count).to eq(1)
    expect(Application.last).to be_valid
  end

  def when_i_start_the_form
    visit Journeys::GetATeacherRelocationPayment::SlugSequence.start_page_url

    click_link("Start")
  end

  def when_i_click_the_back_link
    click_link("Back")
  end

  def when_i_click_the_continue_button
    click_button("Continue")
  end

  def and_i_complete_application_route_question_with(option:)
    raise "Unexpected option: #{option}" unless %w[salaried_trainee teacher].include?(option)

    choose(option:)

    click_button("Continue")
  end

  def and_i_select_my_subject(route)
    assert_i_am_in_the_subject_question(route)

    choose("Physics")

    click_button("Continue")
  end

  def and_i_select_my_visa_type
    assert_i_am_in_the_visa_type_question

    select("Family visa")

    click_button("Continue")
  end

  def and_i_enter_my_entry_date(route)
    assert_i_am_in_the_entry_date_question(route)

    fill_in_date

    click_button("Continue")
  end

  def and_i_enter_my_personal_details
    assert_i_am_in_the_personal_details_question

    fill_in("personal_details_step[given_name]", with: "Bob")
    fill_in("personal_details_step[family_name]", with: "Robertson")
    fill_in("personal_details_step[email_address]", with: "test@example.com")
    fill_in("personal_details_step[phone_number]", with: "01234567890")
    fill_in("Day", with: 1)
    fill_in("Month", with: 1)
    fill_in("Year", with: 1990)
    fill_in("personal_details_step[phone_number]", with: "01234567890")
    fill_in("personal_details_step[address_line_1]", with: "12 Park Gardens")
    fill_in("personal_details_step[address_line_2]", with: "Office 20")
    fill_in("personal_details_step[city]", with: "London")
    fill_in("personal_details_step[postcode]", with: "AS1 1AA")
    select("Senegalese")
    choose("Male")
    fill_in("personal_details_step[passport_number]", with: "000")
    choose("No")

    click_button("Continue")
  end

  def and_i_enter_my_employment_details
    assert_i_am_in_the_employment_details_question

    fill_in("employment_details_step[school_headteacher_name]", with: "Mr Headteacher")
    fill_in("employment_details_step[school_name]", with: "School name")
    fill_in("employment_details_step[school_address_line_1]", with: "1, McSchool Street")
    fill_in("employment_details_step[school_address_line_2]", with: "Schoolville")
    fill_in("employment_details_step[school_city]", with: "Schooltown")
    fill_in("employment_details_step[school_postcode]", with: "SC1 1AA")

    click_button("Continue")
  end

  def and_i_submit_the_application
    click_button("Submit Application")
  end

  def choose_yes
    choose("Yes")

    click_button("Continue")
  end

  def choose_no
    choose("No")

    click_button("Continue")
  end

  def and_i_enter_my_contract_start_date
    assert_i_am_in_the_contract_start_date_question

    fill_in_date

    click_button("Continue")
  end

  def and_i_complete_the_trainee_employment_conditions(choose: "Yes")
    assert_i_am_in_the_trainee_employment_conditions_question

    choose == "Yes" ? choose_yes : choose_no
  end

  def and_i_complete_the_trainee_contract_details_question
    choose_yes
  end

  def and_i_enter_an_invalid_date
    fill_in("Day", with: 31)
    fill_in("Month", with: 2)
    fill_in("Year", with: 2019)

    click_button("Continue")
  end

  def fill_in_date
    three_months_ago = Time.zone.today - 3.months

    fill_in("Day", with: three_months_ago.day)
    fill_in("Month", with: three_months_ago.month)
    fill_in("Year", with: three_months_ago.year)
  end

  def assert_i_am_in_the_subject_question(route)
    expect(page).to have_text(
      "What subject are you employed to teach at your school?"
    )
  end

  def assert_i_am_in_the_contract_start_date_question
    expect(page).to have_text("Enter the start date of your contract")
  end

  def assert_i_am_in_the_employment_details_question
    expect(page).to have_text("Employment information")
  end

  def assert_i_am_in_the_personal_details_question
    expect(page).to have_text("Personal information")
  end

  def assert_i_am_in_the_entry_date_question(route)
    expect(page).to have_text(
      "Enter the date you moved to England to start your teaching job"
    )
  end

  def assert_i_am_in_the_visa_type_question
    expect(page).to have_text("Select the visa you used to move to England")
  end

  def assert_i_am_in_the_application_route_question
    expect(page).to have_text("What is your employment status?")
  end

  def assert_i_am_in_the_trainee_employment_conditions_question
    expect(page).to have_text(
      "Are you on a teacher training course in England which meets the following conditions?"
    )
  end

  def and_i_complete_the_state_school_question
    assert_i_am_in_the_state_school_question

    choose_yes
  end

  def and_i_complete_the_contract_details_question
    assert_i_am_on_the_contract_details_question

    choose_yes
  end

  def then_i_can_see_the_landing_page
    expect(page).to have_text("Apply for the international relocation payment")
  end

  def assert_i_am_in_the_state_school_question
    expect(page).to have_text(
      "Are you employed by an English state secondary school?"
    )
  end

  def assert_i_am_on_the_contract_details_question
    expect(page).to have_text(
      "Are you employed on a contract lasting at least one year?"
    )
  end
end

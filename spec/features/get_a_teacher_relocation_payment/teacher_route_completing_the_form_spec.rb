require "rails_helper"

describe "teacher route: completing the form" do
  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  describe "navigating forward" do
    context "eligible users" do
      it "submits an application" do
        when_i_start_the_form
        and_the_personal_details_section_has_been_temporarily_stubbed
        and_i_submit_the_application
        then_the_application_is_submitted_successfully
      end
    end
  end

  def when_i_start_the_form
    visit Journeys::GetATeacherRelocationPayment::SlugSequence.start_page_url

    click_link("Start")
  end

  def and_i_submit_the_application
    assert_on_check_your_answers_page!

    click_button("Confirm and send")
  end

  # FIXME RL make sure to remove this step it's just a temporary hack until
  # we've added the personal details pages. Really don't want to modify the db
  # in a feature spec!
  # Also we're only temporarily adding the teacher reference number, and
  # payroll gender to get the test to pass as we're not asking for it on the
  # IRP journey.
  def and_the_personal_details_section_has_been_temporarily_stubbed
    journey_session = Journeys::GetATeacherRelocationPayment::Session.last
    journey_session.answers.assign_attributes(
      attributes_for(
        :get_a_teacher_relocation_payment_answers,
        :submitable,
        email_address: "test-irp-claim@example.com",
        teacher_reference_number: "1234567",
        payroll_gender: "male"
      )
    )
    journey_session.save!
  end

  def then_the_application_is_submitted_successfully
    assert_application_is_submitted!
  end

  def assert_on_check_your_answers_page!
    expect(page).to have_text("Check your answers before sending your application")
  end

  def assert_application_is_submitted!
    expect(page).to have_content("Claim submitted")
    expect(page).to have_content(
      "We have sent you a confirmation email to test-irp-claim@example.com"
    )
  end
end

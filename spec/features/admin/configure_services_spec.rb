require "rails_helper"

RSpec.feature "Service configuration" do
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  scenario "when teacher id configurable for service" do
    sign_in_as_service_operator

    click_on "Manage services"
    click_on "Change"

    expect(page).to have_content("Sign in with DfE Identity")
  end

  scenario "Service operator closes a service for submissions" do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Teachers: claim back your student loan repayments")
    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      expect(page).to have_content("Open")
      expect(page).not_to have_content("Closed")
      click_on "Change"
    end

    within_fieldset("Service status") { choose("Closed") }

    fill_in "Availability message", with: "You will be able to make a claim when the service enters public beta in November."

    expect { click_on "Save" }.to_not enqueue_job(SendReminderEmailsJob)

    expect(current_path).to eq(admin_journey_configurations_path)

    expect(journey_configuration.reload.open_for_submissions).to be false
    expect(journey_configuration.availability_message).to eq("You will be able to make a claim when the service enters public beta in November.")

    # - Service operator opens a service for submissions

    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      expect(page).to have_content("Closed")
      expect(page).not_to have_content("Open")

      click_on "Change"
    end

    within_fieldset("Service status") { choose("Open") }

    expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob).with { |arg| expect(arg).to eql(Journeys::TeacherStudentLoanReimbursement) }

    expect(current_path).to eq(admin_journey_configurations_path)

    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      expect(page).to have_content("Open")
      expect(page).not_to have_content("Closed")
    end

    expect(journey_configuration.reload.open_for_submissions).to be true
  end

  context "Reminders exist" do
    let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments) }
    let(:count) { [*1..5].sample }

    before do
      create_list(:reminder, count, :with_targeted_retention_incentive_payments_reminder, email_verified: true, itt_academic_year: AcademicYear.current)
      # should not be included
      create(:reminder, :with_fe_reminder, email_verified: true, itt_academic_year: AcademicYear.next)
      create(:reminder, :with_fe_reminder, email_verified: true, itt_academic_year: AcademicYear.current, email_sent_at: Date.today)
      create(:reminder, :with_fe_reminder, email_verified: false, itt_academic_year: AcademicYear.current)
      # sendable reminders for a different journey should not be included in the count
      create_list(:reminder, 3, :with_fe_reminder, email_verified: true, itt_academic_year: AcademicYear.current)
    end

    scenario "Service operator opens an TRI service for submissions" do
      journey_configuration.update(open_for_submissions: false)
      sign_in_as_service_operator

      click_on "Manage services"

      expect(page).to have_content("Claim additional payments for teaching")
      within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
        expect(page).to have_content("Closed")
        expect(page).not_to have_content("Open")
        click_on "Change"
      end

      within(".govuk-radios__conditional--hidden#reminders-warning-message") do
        expect(page).to have_content(I18n.t("admin.journey_configuration.reminder_warning", count: count))
      end

      within_fieldset("Service status") { choose("Open") }
      expect(page).to have_content(I18n.t("admin.journey_configuration.reminder_warning", count: count))
      # make sure email reminder job is queued
      expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob)
      expect(current_path).to eq(admin_journey_configurations_path)

      within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
        expect(page).to have_content("Open")
        expect(page).not_to have_content("Closed")
      end

      expect(journey_configuration.reload.open_for_submissions).to be true
    end
  end

  scenario "Service operator changes the academic year a service is accepting payments for" do
    travel_to Date.new(2023) do
      sign_in_as_service_operator

      click_on "Manage services"

      within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
        click_on "Change"
      end

      select "2023/2024", from: "Accepting claims for academic year"
      expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob).with { |arg| expect(arg).to eql(journey_configuration.journey) }

      within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
        expect(page).to have_content("2023/2024")
      end

      expect(journey_configuration.reload.current_academic_year).to eq AcademicYear.new(2023)
    end
  end
end

RSpec.feature "Service configuration" do
  let(:journey_configuration) { create(:journey_configuration, :further_education_payments) }

  scenario "when teacher id not configurable for service" do
    given_journey_configuration
    sign_in_as_service_operator

    click_on "Manage services"
    click_on "Change Claim a targeted retention incentive payment for further education teachers"

    expect(page).not_to have_content("Sign in with DfE Identity")
  end

  scenario "toggle FE provider dashboard", feature_flag: [:fe_provider_dashboard] do
    given_journey_configuration
    sign_in_as_service_operator

    click_on "Manage services"
    click_on "Change Claim a targeted retention incentive payment for further education teachers"

    expect(FeatureFlag).to be_enabled("fe_provider_dashboard")

    choose "Disabled"
    click_button "Save feature flags"

    expect(FeatureFlag).to be_disabled("fe_provider_dashboard")

    choose "Enabled"
    click_button "Save feature flags"

    expect(FeatureFlag).to be_enabled("fe_provider_dashboard")
  end

  def given_journey_configuration
    journey_configuration
  end
end

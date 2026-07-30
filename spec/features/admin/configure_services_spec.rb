require "rails_helper"

RSpec.feature "Service configuration" do
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  def future_close_at_form_value(days_from_now = 1)
    Time.zone.now.in_time_zone("London").advance(days: days_from_now).strftime("%Y-%m-%dT%H:%M")
  end

  scenario "when teacher id configurable for service" do
    sign_in_as_service_operator

    click_on "Manage services"
    within(page.find("tr", text: journey_configuration.journey.full_name)) do
      click_on "Change"
    end

    expect(page).to have_content("Sign in with DfE Identity")
  end

  scenario "Service operator closes a service for submissions", js: true do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Teachers: claim back your student loan repayments")
    within(page.find("tr", text: journey_configuration.journey.full_name)) do
      expect(page).to have_content("Open")
      expect(page).not_to have_content("Closed")
      click_on "Change"
    end

    within_fieldset("Service status") { choose("Open") }

    find("#close-at").set(future_close_at_form_value(7))

    within_fieldset("Service status") { choose("Closed") }

    expect { click_on "Save" }.to_not enqueue_job(SendReminderEmailsJob)

    expect(current_path).to eq(edit_admin_journey_configuration_path(journey_configuration))

    expect(page).to have_content("Closed")
    expect(journey_configuration.reload.open_for_submissions).to be false

    # - Service operator opens a service for submissions

    visit admin_journey_configurations_path

    within(page.find("tr", text: journey_configuration.journey.full_name)) do
      expect(page).to have_content("Closed")
      expect(page).not_to have_content("Open")

      click_on "Change"
    end

    within_fieldset("Service status") { choose("Open") }

    find("#close-at").set(future_close_at_form_value(7))

    expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob).with { |arg| expect(arg).to eql(Journeys::TeacherStudentLoanReimbursement) }

    expect(page).to have_content("Service open")
  end

  scenario "selecting Open shows close date and close time fields", js: true do
    sign_in_as_service_operator

    click_on "Manage services"

    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      click_on "Change"
    end

    expect(page).to have_css("#close-at")
    expect(page).to have_css("#close-at[min]")

    within_fieldset("Service status") { choose("Open") }

    expect(page).to have_css("#close-at")
    expect(page).to have_css("#close-at[min]")
  end

  scenario "shows saved close date and close time values in the edit fields", js: true do
    journey_configuration.update!(close_at: Time.zone.now.in_time_zone("London").advance(days: 7))

    sign_in_as_service_operator

    click_on "Manage services"

    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      click_on "Change"
    end

    within_fieldset("Service status") { choose("Open") }

    expect(page).to have_field("close-at", with: journey_configuration.reload.close_at.in_time_zone("London").strftime("%Y-%m-%dT%H:%M"))
  end

  scenario "submitting Open with empty close date and close time shows errors for supported journeys", js: true do
    eytfi_journey_configuration = create(:journey_configuration, :early_years_teachers_financial_incentive_payments)

    sign_in_as_service_operator

    [journey_configuration, eytfi_journey_configuration].each do |configuration|
      visit admin_journey_configurations_path

      within(find("tr[data-policy-configuration-routing-name=\"#{configuration.routing_name}\"]")) do
        click_on "Change"
      end

      within_fieldset("Service status") { choose("Open") }

      click_on "Save"

      expect(configuration.reload.open_for_submissions).to be true
    end
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
      journey_configuration.update_column(:open_for_submissions, false)
      sign_in_as_service_operator

      click_on "Manage services"

      expect(page).to have_content("Claim additional payments for teaching")
      within(page.find("tr", text: journey_configuration.journey.full_name)) do
        expect(page).to have_content("Closed")
        expect(page).not_to have_content("Open")
        click_on "Change"
      end

      within(".govuk-radios__conditional--hidden#reminders-warning-message") do
        expect(page).to have_content(I18n.t("admin.journey_configuration.reminder_warning", count: count))
      end

      within_fieldset("Service status") { choose("Open") }
      find("#close-at").set(future_close_at_form_value(7))
      expect(page).to have_content(I18n.t("admin.journey_configuration.reminder_warning", count: count))
      # make sure email reminder job is queued
      expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob)
      expect(current_path).to eq(edit_admin_journey_configuration_path(journey_configuration))

      expect(page).to have_content("Service open")
      expect(page).to have_css("input[name='journey_configuration[open_for_submissions]'][value='true'][checked]")

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
      find("#close-at").set(future_close_at_form_value(7))
      expect { click_on "Save" }.to enqueue_job(SendReminderEmailsJob).with { |arg| expect(arg).to eql(journey_configuration.journey) }

      expect(page).to have_content(AcademicYear.new(2023).to_s)

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

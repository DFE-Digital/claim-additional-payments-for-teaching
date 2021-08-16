require "rails_helper"

RSpec.feature "Service configuration" do
  let(:policy_configuration) { policy_configurations(:student_loans) }

  scenario "Service operator closes a service for submissions" do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Teachers: claim back your student loan repayments")
    within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
      expect(page).to have_content("Open")
      expect(page).not_to have_content("Closed")
      click_on "Change"
    end

    within_fieldset("Service status") { choose("Closed") }

    fill_in "Availability message", with: "You will be able to make a claim when the service enters public beta in November."

    click_on "Save"

    expect(current_path).to eq(admin_policy_configurations_path)

    within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
      expect(page).to have_content("Closed")
      expect(page).not_to have_content("Open")
    end

    expect(policy_configuration.reload.open_for_submissions).to be false
    expect(policy_configuration.availability_message).to eq("You will be able to make a claim when the service enters public beta in November.")
  end

  scenario "Service operator opens a service for submissions" do
    policy_configuration.update(open_for_submissions: false)

    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Teachers: claim back your student loan repayments")
    within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
      expect(page).to have_content("Closed")
      expect(page).not_to have_content("Open")
      click_on "Change"
    end

    within_fieldset("Service status") { choose("Open") }

    click_on "Save"

    expect(current_path).to eq(admin_policy_configurations_path)

    within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
      expect(page).to have_content("Open")
      expect(page).not_to have_content("Closed")
    end

    expect(policy_configuration.reload.open_for_submissions).to be true
  end

  context "Reminders exist" do
    let(:policy_configuration) { policy_configurations(:early_career_payments) }
    let(:count) { [*1..5].sample }
    let(:reminders) do
      create_list(:reminder, count)
    end
    scenario "Service operator opens an ECP service for submissions" do
      policy_configuration.update(open_for_submissions: false)
  
      sign_in_as_service_operator
  
      click_on "Manage services"
  
      expect(page).to have_content("Claim an early-career payment")
      within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
        expect(page).to have_content("Closed")
        expect(page).not_to have_content("Open")
        click_on "Change"
      end
      expect(page).to_not have_content(I18n.t("admin.policy_configuration.reminder_warning", count: count))
      within_fieldset("Service status") { choose("Open") }
      expect(page).to have_content(I18n.t("admin.policy_configuration.reminder_warning", count: count))
      click_on "Save"
  
      expect(current_path).to eq(admin_policy_configurations_path)
  
      within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
        expect(page).to have_content("Open")
        expect(page).not_to have_content("Closed")
      end
  
      expect(policy_configuration.reload.open_for_submissions).to be true
    end
  
  end
  scenario "Service operator changes the academic year a service is accepting payments for" do
    travel_to Date.new(2023) do
      sign_in_as_service_operator

      click_on "Manage services"

      within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
        click_on "Change"
      end

      select "2023/2024", from: "Accepting claims for academic year"
      click_on "Save"

      within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
        expect(page).to have_content("2023/2024")
      end

      expect(policy_configuration.reload.current_academic_year).to eq AcademicYear.new(2023)
    end
  end
end

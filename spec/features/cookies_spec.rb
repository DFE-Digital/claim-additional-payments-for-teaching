require "rails_helper"

[true, false].each do |with_js|
  text = with_js ? "with JS" : "without JS"

  RSpec.feature "Cookies #{text}", js: with_js, flaky: with_js do
    before do
      when_further_education_payments_journey_configuration_exists
    end

    scenario "accept cookies" do
      visit "/further-education-payments/landing-page"

      expect(page).to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"

      click_button "Accept additional cookies"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).to have_content "You have accepted additional cookies"

      click_button "Hide cookie message"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"

      click_link "Cookies"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"

      expect(page).to have_selector "input[type=radio][id=cookies-accept-true-field][checked=checked]", visible: false
    end

    scenario "accept cookies on cookies page" do
      visit "/further-education-payments/cookies"

      expect(page).to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"

      expect(page).to have_unchecked_field("cookies-accept-true-field", visible: false)
      expect(page).to have_unchecked_field("cookies-accept-field", visible: false)

      choose "Yes"
      click_button "Save cookie settings"

      expect(page).to have_checked_field("cookies-accept-true-field", visible: false)
      expect(page).to have_unchecked_field("cookies-accept-field", visible: false)

      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).to have_content "You have accepted additional cookies"

      click_button "Hide cookie message"

      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"
    end

    scenario "reject cookies" do
      visit "/further-education-payments/landing-page"

      expect(page).to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have rejected additional cookies"

      click_button "Reject additional cookies"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).to have_content "You have rejected additional cookies"

      click_button "Hide cookie message"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have rejected additional cookies"

      click_link "Cookies"
      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have rejected additional cookies"

      expect(page).to have_selector "input[type=radio][id=cookies-accept-field][checked=checked]", visible: false
    end

    scenario "reject cookies on cookies page" do
      visit "/further-education-payments/cookies"

      expect(page).to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have accepted additional cookies"

      expect(page).to have_unchecked_field("cookies-accept-true-field", visible: false)
      expect(page).to have_unchecked_field("cookies-accept-field", visible: false)

      choose "No"
      click_button "Save cookie settings"

      expect(page).to have_unchecked_field("cookies-accept-true-field", visible: false)
      expect(page).to have_checked_field("cookies-accept-field", visible: false)

      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).to have_content "You have rejected additional cookies"

      click_button "Hide cookie message"

      expect(page).not_to have_content "We use some essential cookies to make this service work"
      expect(page).not_to have_content "You have rejected additional cookies"
    end
  end
end

require "rails_helper"

RSpec.describe "Visit admin", :smoke, type: :feature do
  # To test this locally you will need to add to your .env file:
  #
  # SMOKE_TEST_APP_HOST
  # BASIC_AUTH_USERNAME
  # BASIC_AUTH_PASSWORD

  scenario "User visits admin" do
    visit url_with_basic_auth
    expect(page).to have_text(I18n.t("service_name"))
  end

  def url_with_basic_auth
    host = ENV.fetch("SMOKE_TEST_APP_HOST")
    path = admin_root_path
    uri = URI.join(host, path)

    username = ENV.fetch("BASIC_AUTH_USERNAME", nil)
    password = ENV.fetch("BASIC_AUTH_PASSWORD", nil)

    if username.present? && password.present?
      uri.user = username
      uri.password = password
    end

    uri.to_s
  end
end

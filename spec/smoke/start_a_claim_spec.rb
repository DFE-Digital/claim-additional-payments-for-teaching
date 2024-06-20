require "rails_helper"

RSpec.describe "Start a claim", :smoke, type: :feature do
  # To test this locally you will need to add to your .env file:
  #
  # SMOKE_TEST_APP_HOST
  # BASIC_AUTH_USERNAME
  # BASIC_AUTH_PASSWORD

  scenario "User starts a claim" do
    visit url_with_basic_auth
    expect(page).to have_text("Teachers: claim back your student loan repayments")
  end

  def url_with_basic_auth
    uri = URI.parse(new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME))

    uri.user = ENV.fetch("BASIC_AUTH_USERNAME", nil)
    uri.password = ENV.fetch("BASIC_AUTH_PASSWORD", nil)
    uri.to_s
  end
end

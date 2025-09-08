require "rails_helper"

RSpec.feature "Admin claim support tickets" do
  before do
    create(:journey_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "the service operator adds a support ticket to a claim" do
    claim = create(:claim, :submitted)

    visit admin_claims_path

    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on "Notes and support"

    expect(page).to have_link("View all support tickets in Zendesk", href: "https://becomingateacher.zendesk.com/agent/search/1?copy&type=ticket&q=person1%40example.com")

    fill_in "Support ticket", with: "https://account-sub-domain.zendesk.com/agent/tickets/1638"
    click_on "Save support ticket"

    expect(claim.support_ticket).to be_present
    expect(claim.support_ticket.url).to eq("https://account-sub-domain.zendesk.com/agent/tickets/1638")
    expect(claim.support_ticket.created_by).to eq(@signed_in_user)

    expect(page).to have_link(href: "https://account-sub-domain.zendesk.com/agent/tickets/1638")
    expect(page).to have_link("View all support tickets in Zendesk", href: "https://becomingateacher.zendesk.com/agent/search/1?copy&type=ticket&q=person1%40example.com")
  end
end

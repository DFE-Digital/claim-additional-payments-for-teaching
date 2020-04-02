require "rails_helper"

RSpec.describe SupportTicket, type: :model do
  it "validates the url attribute is a valid HTTP URL" do
    support_ticket = build(:support_ticket)

    support_ticket.url = "http://example.com/a-page"
    expect(support_ticket).to be_valid

    support_ticket.url = "https://example.com/a-page"
    expect(support_ticket).to be_valid

    support_ticket.url = "not-a-url"
    expect(support_ticket).not_to be_valid
    expect(support_ticket.errors.messages[:url]).to eq(["Enter a valid support ticket URL"])
  end
end

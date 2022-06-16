require "rails_helper"

RSpec.describe LevellingUpPremiumPayments, type: :model do
  specify {
    expect(subject).to have_attributes(routing_name: "early-career-payments",
      short_name: "Levelling Up Premium Payments",
      locale_key: "levelling_up_premium_payments",
      notify_reply_to_id: "3f85a1f7-9400-4b48-9a31-eaa643d6b977",
      eligibility_page_url: "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers")
  }
end

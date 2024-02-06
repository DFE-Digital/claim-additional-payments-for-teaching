require "rails_helper"

RSpec.describe LevellingUpPremiumPayments, type: :model do
  it { expect(subject.const_defined?(:VERIFIERS)).to eq(true) }

  specify {
    expect(subject).to have_attributes(routing_name: "additional-payments",
      short_name: "Levelling Up Premium Payments",
      locale_key: "levelling_up_premium_payments",
      notify_reply_to_id: "03ece7eb-2a5b-461b-9c91-6630d0051aa6",
      eligibility_page_url: "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers",
      eligibility_criteria_url: "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers#eligibility-criteria-for-teachers")
  }
end

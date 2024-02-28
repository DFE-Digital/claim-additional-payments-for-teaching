require "rails_helper"

describe Admin::AmendmentsHelper do
  describe ".editable_award_amount_policy?" do
    specify { expect(editable_award_amount_policy?(Policies::EarlyCareerPayments)).to be true }
    specify { expect(editable_award_amount_policy?(LevellingUpPremiumPayments)).to be true }
    specify { expect(editable_award_amount_policy?(StudentLoans)).to be false }
  end
end

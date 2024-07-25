require "rails_helper"

RSpec.feature "Admin view claim" do
  Policies.all.each do |policy|
    # FIXME RL temp stub out this test until we've added rejection reasons for
    # IRP
    unless policy == Policies::InternationalRelocationPayments
      it_behaves_like "Admin View Claim Feature", policy
    end
  end
end

require "rails_helper"

RSpec.feature "Admin claim allocation and deallocation" do
  Journey.all_policies.each { |policy| it_behaves_like "Admin Claim Allocation and Deallocation Feature", policy }
end

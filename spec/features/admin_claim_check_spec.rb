require "rails_helper"

RSpec.feature "Admin checks a claim" do
  PolicyConfiguration.all_policies.each { |policy| it_behaves_like "Admin Check Claim Feature", policy }
end

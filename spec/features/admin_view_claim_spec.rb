require "rails_helper"

RSpec.feature "Admin view claim" do
  Journey.all_policies.each { |policy| it_behaves_like "Admin View Claim Feature", policy }
end

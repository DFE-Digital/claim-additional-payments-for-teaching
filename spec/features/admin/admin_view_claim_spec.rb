require "rails_helper"

RSpec.feature "Admin view claim" do
  Policies.all.each { |policy| it_behaves_like "Admin View Claim Feature", policy }
end

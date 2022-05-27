require "rails_helper"

RSpec.feature "Admin search" do
  PolicyConfiguration.all_policies.each { |policy| it_behaves_like "Admin Search Feature", policy }
end

require "rails_helper"

RSpec.feature "Admin search" do
  Policies.all.each { |policy| it_behaves_like "Admin Search Feature", policy }
end

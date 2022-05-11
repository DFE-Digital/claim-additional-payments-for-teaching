require "rails_helper"

RSpec.describe Claim::Search do
  it_behaves_like "Admin Searchable Claim", LevellingUpPayments
  it_behaves_like "Admin Searchable Claim", EarlyCareerPayments
  it_behaves_like "Admin Searchable Claim", StudentLoans
  it_behaves_like "Admin Searchable Claim", MathsAndPhysics
end

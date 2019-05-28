require "rails_helper"

RSpec.describe LocalAuthorityDistrict, type: :model do
  it { should have_many(:schools) }
end

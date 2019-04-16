require "rails_helper"

RSpec.describe LocalAuthority, type: :model do
  it { should have_many(:schools) }
end

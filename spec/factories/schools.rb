FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "Acme Secondary School" }
    school_type { :community_school }
    school_type_group { :la_maintained }
    phase { :secondary }
    local_authority
  end
end

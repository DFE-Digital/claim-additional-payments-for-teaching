FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "Acme Secondary School" }
    school_type { :community_school }
    school_type_group { :la_maintained }
    phase { :secondary }
    local_authority
    local_authority_district

    trait :student_loan_eligible do
      local_authority { LocalAuthority.find(ActiveRecord::FixtureSet.identify(:barnsley, :uuid)) }
      school_type_group { School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.sample }
      phase { School::SECONDARY_PHASES.sample }
    end

    trait :maths_and_physics_eligible do
      local_authority_district { LocalAuthorityDistrict.find(ActiveRecord::FixtureSet.identify(:barnsley, :uuid)) }
      school_type_group { School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.sample }
      phase { School::SECONDARY_PHASES.sample }
    end
  end
end

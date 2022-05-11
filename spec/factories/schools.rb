FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "Acme Secondary School" }
    school_type { :community_school }
    school_type_group { :la_maintained }
    phase { :secondary }
    sequence(:phone_number) { |n| "01612733#{n}" }

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

    trait :early_career_payments_eligible do
      local_authority_district { LocalAuthorityDistrict.find(ActiveRecord::FixtureSet.identify(:barnsley, :uuid)) }
      school_type_group { School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.sample }
      phase { School::SECONDARY_PHASES.sample }
    end

    trait :levelling_up_payments_eligible do
      # fake whilst set of eligible schools is outside public domain
      sequence(:urn, 150000)
    end

    trait :levelling_up_payments_ineligible do
      # fake whilst set of eligible schools is outside public domain
      sequence(:urn, 160000)
    end

    trait :not_found_in_levelling_up_payments_spreadsheet do
      # fake whilst set of eligible schools is outside public domain
      sequence(:urn, 170000)
    end
  end
end

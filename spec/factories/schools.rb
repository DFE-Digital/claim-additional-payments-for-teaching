FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "Acme Secondary School" }
    school_type { :community_school }
    school_type_group { :la_maintained }
    phase { :secondary }
    local_authority
    local_authority_district

    trait :tslr_eligible do
      local_authority { create(:local_authority, code: StudentLoans::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_CODES.sample) }
      school_type_group { School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.sample }
      phase { StudentLoans::SchoolEligibility::ELIGIBLE_PHASES.sample }
    end
  end
end

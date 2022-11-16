FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "#{Faker::Company.unique.name} School" }
    school_type { :community_school }
    school_type_group { :la_maintained }
    phase { :secondary }
    sequence(:phone_number) { |n| "01612733#{n}" }
    postcode { Faker::Address.unique.postcode }
    establishment_number { Faker::Number.unique.number(digits: 4) }

    local_authority
    association :local_authority_district

    trait :student_loans_eligible do
      association :local_authority, :student_loans_eligible
      state_funded
      secondary_equivalent
      open
    end

    trait :student_loans_ineligible do
      student_loans_eligible
      association :local_authority, :student_loans_ineligible
      not_state_funded
      not_secondary_equivalent
    end

    trait :maths_and_physics_eligible do
      association :local_authority_district, :maths_and_physics_eligible
      state_funded
      secondary_equivalent
      open
    end

    trait :maths_and_physics_ineligible do
      maths_and_physics_eligible
      association :local_authority_district, :maths_and_physics_ineligible
    end

    trait :maths_and_physics_explicitly_eligible do
      maths_and_physics_ineligible
      urn { MathsAndPhysics::SchoolEligibility::SCHOOL_URNS_CONSIDERED_AS_ELIGIBLE_LOCAL_AUTHORITY_DISTRICT.sample }
    end

    trait :early_career_payments_eligible do
      association :local_authority_district, :early_career_payments_no_uplift
      state_funded
      secondary_equivalent
      open
    end

    trait :early_career_payments_uplifted do
      early_career_payments_eligible
      association :local_authority_district, :early_career_payments_uplifted
    end

    trait :early_career_payments_explicitly_eligible do
      early_career_payments_eligible
      local_authority_district { nil }
      urn { EarlyCareerPayments::SchoolEligibility::SCHOOL_URNS_CONSIDERED_AS_ELIGIBLE_LOCAL_AUTHORITY_DISTRICT.sample }
    end

    trait :early_career_payments_ineligible do
      association :local_authority_district, :early_career_payments_ineligible
      state_funded
      not_secondary_equivalent
    end

    trait :levelling_up_premium_payments_eligible do
      # this is a huge array but if it ever cycles, there'll be a message about duplicate URNs
      # TODO: 2022 should not be hard-coded here
      sequence :urn, LevellingUpPremiumPayments::Award.urn_to_award_amount_in_pounds(AcademicYear.new(2022)).keys.cycle
    end

    trait :levelling_up_premium_payments_ineligible do
      sequence(:urn, 170000)
    end

    trait :combined_journey_eligibile_for_all do
      early_career_payments_eligible
      levelling_up_premium_payments_eligible
    end

    trait :state_funded do
      school_type_group { School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.sample }
    end

    trait :not_state_funded do
      school_type_group { (School::SCHOOL_TYPE_GROUPS.keys.map(&:to_s) - School::STATE_FUNDED_SCHOOL_TYPE_GROUPS).sample }
    end

    trait :special_school do
      school_type { :community_special_school }
      school_type_group { :special_schools }
    end

    trait :secondary_equivalent do
      statutory_high_age { 16 }
      phase { School::SECONDARY_PHASES.sample }
    end

    trait :not_secondary_equivalent do
      statutory_high_age { 11 }
      phase { (School::PHASES.keys.map(&:to_s) - School::SECONDARY_PHASES).sample }
    end

    trait :alternative_provision do
      school_type_group { :la_maintained }
      school_type { :pupil_referral_unit }
    end

    trait :secure_unit do
      school_type_group { :other }
      school_type { :secure_unit }
    end

    trait :city_technology_college do
      school_type { :city_technology_college }
      school_type_group { :independent_schools }
    end

    trait :closed do
      open_date { 100.days.ago }
      close_date { 10.days.ago }
    end

    trait :open do
      open_date { 10.days.ago }
      close_date { nil }
    end
  end
end

FactoryBot.define do
  factory :school do
    transient do
      journey { nil }
    end

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

    trait :eligible_for_journey do
      after(:build) do |school, evaluator|
        case evaluator.journey
        when Journeys::AdditionalPaymentsForTeaching
          build(:school, :combined_journey_eligibile_for_all)
        when Journeys::TeacherStudentLoanReimbursement
          build(:school, :student_loans_eligible)
        else
          raise "school trait :eligible_for_journey not available for #{evaluator.journey} "
        end
      end
    end

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
      urn { Policies::EarlyCareerPayments::SchoolEligibility::SCHOOL_URNS_CONSIDERED_AS_ELIGIBLE_LOCAL_AUTHORITY_DISTRICT.sample }
    end

    trait :early_career_payments_ineligible do
      association :local_authority_district, :early_career_payments_ineligible
      state_funded
      not_secondary_equivalent
    end

    trait :targeted_retention_incentive_payments_eligible do
      transient do
        targeted_retention_incentive_payments_award_amount { 2_000 }
      end

      after(:build) do |school, evaluator|
        create(:targeted_retention_incentive_payments_award, school: school, award_amount: evaluator.targeted_retention_incentive_payments_award_amount)
      end
    end

    trait :targeted_retention_incentive_payments_ineligible do
      sequence(:urn, 170000)
    end

    trait :combined_journey_eligibile_for_all do
      early_career_payments_eligible
      targeted_retention_incentive_payments_eligible
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

    trait :further_education do
      ukprn { rand(10_000_000..19_000_000) }
      phase { 6 }
    end

    trait :fe_eligible do
      further_education

      after(:create) do |school, evaluator|
        create(:eligible_fe_provider, ukprn: school.ukprn)
      end
    end

    factory :fe_eligible_school, traits: [:fe_eligible]
  end
end

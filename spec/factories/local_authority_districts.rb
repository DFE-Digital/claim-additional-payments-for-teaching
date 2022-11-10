FactoryBot.define do
  factory :local_authority_district do
    name { Faker::Address.community }
    sequence(:code, 1000) { |n| "E0000#{n}" }

    trait :early_career_payments_eligible do
      code { Thread.current[:factory_registry].find(:local_authority_district_ecp_eligible_codes).shuffle!.pop }
    end

    trait :early_career_payments_uplifted do
      code { Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes).shuffle!.pop }
    end

    trait :early_career_payments_no_uplift do
      code do
        value = (Thread.current[:factory_registry].find(:local_authority_district_ecp_eligible_codes) - Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes)).sample
        Thread.current[:factory_registry].find(:local_authority_district_ecp_eligible_codes).delete(value)
        value
      end
    end

    trait :early_career_payments_ineligible do
    end

    trait :maths_and_physics_eligible do
      code { Thread.current[:factory_registry].find(:local_authority_district_maths_and_physics_eligible_codes).shuffle!.pop }
    end

    trait :ecp_and_maths_uplifted do
      code do
        value = (Thread.current[:factory_registry].find(:local_authority_district_maths_and_physics_eligible_codes) & Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes)).sample
        Thread.current[:factory_registry].find(:local_authority_district_maths_and_physics_eligible_codes).delete(value)
        Thread.current[:factory_registry].find(:local_authority_district_ecp_uplift_codes).delete(value)
        value
      end
    end

    trait :maths_and_physics_ineligible do
      code { ["E08000005", "E09000007"].sample }
    end
  end
end

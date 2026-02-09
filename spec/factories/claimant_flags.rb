FactoryBot.define do
  factory :claimant_flag do
    identification_attribute { "national_insurance_number" }
    identification_value { "AB123456C" }
    reason { "clawback" }
    suggested_action { "Speak to manager" }
    policy { "FurtherEducationPayments" }
    previous_claim { nil }
  end
end

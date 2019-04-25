FactoryBot.define do
  factory :school do
    sequence(:urn)
    name { "Acme Secondary School" }
    school_type { 10 }
    school_type_group { 5 }
    phase { 4 }
    local_authority
  end
end

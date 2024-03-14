# frozen_string_literal: true

FactoryBot.define do
  factory :irp_eligibility, class: "Irp::Eligibility" do
    trait :eligible do
      one_year { true }
      state_funded_secondary_school { true }
      date_of_entry { 2.months.ago }
      start_date { 2.months.ago }
      application_route { Faker::Job.field }
      ip_address { Faker::Internet.ip_v4_address }
      nationality { Faker::Nation.nationality }
      passport_number { Faker::IDNumber.valid }
      school_headteacher_name { Faker::Name.name }
      school_name { Faker::Educator.secondary_school }
      school_address_line_1 { Faker::Address.street_address }
      school_address_line_2 { Faker::Address.secondary_address }
      school_city { Faker::Address.city }
      school_postcode { Faker::Address.postcode }
      subject { Faker::Educator.subject }
      visa_type { Faker::Lorem.word }
    end

    trait :ineligible do
      eligible
      start_date { 1.year.ago }
    end
  end
end

FactoryBot.define do
  factory :eligible_eytfi_provider, class: "Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider" do
    file_upload {
      FileUpload.latest_version_for(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider).first ||
        create(:file_upload, target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.to_s)
    }

    urn { "EY#{rand(100000..999999)}" }
    name { Faker::Company.name }
    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_line_3 { Faker::Address.community }
    town { Faker::Address.city }
    postcode { "EC1N 2TD" }
    eligible { true }
  end
end

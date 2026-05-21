FactoryBot.define do
  factory(
    :early_years_teachers_financial_incentive_payments_eligibility,
    class: "Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility"
  ) do
    transient do
      eligible_eytfi_provider { create(:eligible_eytfi_provider) }
    end

    eligible_eytfi_provider_urn { eligible_eytfi_provider.urn }

    trait :with_trs_data do
      trs_data do
        {
          "trn" => "3013822",
          "firstName" => "Newell",
          "middleName" => "",
          "lastName" => "Ondricka",
          "dateOfBirth" => "1960-01-01",
          "nationalInsuranceNumber" => "LC882331C",
          "emailAddress" => nil,
          "qts" => nil,
          "eyts" => {
            "holdsFrom" => "2026-01-01",
            "routes" => [
              {
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "11b66de5-4670-4c82-86aa-20e42df723b7",
                  "name" => "Early Years Teacher Degree Apprenticeship",
                  "professionalStatusType" => "EarlyYearsTeacherStatus"
                }
              }
            ]
          },
          "qtlsStatus" => "None"
        }
      end

      trs_data_fetched_at { DateTime.new(2026, 5, 19, 15, 0, 0) }
    end

    trait :eligible do
    end
  end
end

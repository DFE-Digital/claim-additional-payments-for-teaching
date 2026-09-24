# Run me with `rails runner db/data/20260923135457_populate_eytfi_provider_sanitised_name.rb`

Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
  .update_all("sanitised_name = regexp_replace(\"name\", '\\W', '', 'g')")

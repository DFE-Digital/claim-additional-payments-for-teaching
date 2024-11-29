class AddIndexesToClaimsForDuplicateDetection < ActiveRecord::Migration[7.2]
  def change
    add_index(
      :claims,
      'LOWER(email_address)',
      name: 'index_claims_on_lower_email_address'
    )

    add_index(
      :claims,
      'LOWER(national_insurance_number)',
      name: 'index_claims_on_lower_national_insurance_number'
    )

    add_index(
      :claims,
      %w(bank_account_number bank_sort_code),
      name: 'index_claims_on_bank_details'
    )

    add_index(
      :claims,
      'LOWER(first_name), LOWER(surname), date_of_birth',
      name: 'index_claims_on_personal_details'
    )
  end
end

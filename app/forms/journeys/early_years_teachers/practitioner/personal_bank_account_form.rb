module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class PersonalBankAccountForm < ::PersonalBankAccountForm
        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            banking_name: banking_name,
            bank_sort_code: normalised_bank_detail(bank_sort_code),
            bank_account_number: normalised_bank_detail(bank_account_number)
          )

          journey_session.save!
        end

        private

        def bank_account_is_valid
          # Skip HMRC validation for prototype/user research
        end
      end
    end
  end
end

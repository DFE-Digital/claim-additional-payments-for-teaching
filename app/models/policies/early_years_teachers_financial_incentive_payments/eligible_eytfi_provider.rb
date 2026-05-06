module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class EligibleEytfiProvider < ApplicationRecord
      belongs_to :file_upload

      scope :by_academic_year, ->(academic_year) do
        where(
          file_upload: FileUpload.latest_version_for(
            EligibleEytfiProvider,
            academic_year
          )
        )
      end
    end
  end
end

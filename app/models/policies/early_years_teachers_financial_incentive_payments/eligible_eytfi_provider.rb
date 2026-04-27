module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class EligibleEytfiProvider < ApplicationRecord
      attribute :academic_year, AcademicYear::Type.new
      belongs_to :file_upload

      scope :by_academic_year, ->(academic_year) {
        where(file_upload: FileUpload.latest_version_for(EligibleFeProvider, academic_year))
      }
    end
  end
end

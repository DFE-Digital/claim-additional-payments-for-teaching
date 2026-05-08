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

      before_save do
        self.sanitised_postcode = postcode&.downcase&.delete(" ").presence
      end

      scope :search, ->(search_term) do
        search_field = :name
        sanitised_search_term = search_term.delete(" ")

        # Some school names may start with a postcode-resembling pattern, so the following check is not meant
        # to provide 100% accurate inference, but rather cover most cases and still allow partial-postcode search.
        if sanitised_search_term.length.between?(3, 7) && sanitised_search_term.match?(School::POSTCODE_SEARCH_REGEX)
          search_field, search_term = [:sanitised_postcode, sanitised_search_term]
        end

        where("#{search_field} ILIKE ?", "%#{sanitize_sql_like(search_term)}%")
          .order(sanitize_sql_for_order([Arel.sql("similarity(#{search_field}, ?) DESC"), search_term]))
          .order(:name)
          .limit(School::SEARCH_RESULTS_LIMIT)
      end

      def address
        [
          address_line_1,
          address_line_2,
          address_line_3,
          town,
          postcode
        ].compact_blank.join(", ")
      end

      def closed?
        false
      end

      def ineligible?
        !eligible
      end
    end
  end
end

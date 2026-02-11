module Admin
  module FurtherEducationPayments
    class FlaggedProvidersCsvForm
      include ActiveModel::Model

      attr_accessor :admin, :file

      HEADERS = %w[ukprn reason].freeze

      validates :admin, presence: true

      validate :csv_is_parseable
      validate :csv_has_expected_headers, if: :csv_is_parseable?
      validate(
        :all_ukprns_match_a_provider,
        if: -> { csv_is_parseable? && csv_has_expected_headers? }
      )

      def initialize(params)
        super
      end

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          Policies::FurtherEducationPayments::ProviderFlag.all.each(&:destroy!)
          flags.each(&:save!)
        end

        true
      end

      private

      def flags
        @flags ||= csv.map do |row|
          Policies::FurtherEducationPayments::ProviderFlag.new(
            academic_year: AcademicYear.current,
            ukprn: row["ukprn"],
            reason: row["reason"]
          )
        end
      end

      def csv
        @csv ||= CSV.parse(file.read, headers: true, skip_blanks: true)
      end

      def csv_is_parseable
        unless csv_is_parseable?
          errors.add(:file, "CSV file is invalid")
        end
      end

      def csv_is_parseable?
        csv
        true
      rescue CSV::MalformedCSVError
        false
      end

      def csv_has_expected_headers?
        Set.new(csv.headers) == Set.new(HEADERS)
      end

      def csv_has_expected_headers
        unless csv_has_expected_headers?
          errors.add(:file, "Missing expected headers '#{HEADERS.join(",")}'")
        end
      end

      def all_ukprns_match_a_provider
        flags.select(&:invalid?).each do |flag|
          errors.add(
            :file,
            message: flag.errors.full_messages.to_sentence
          )
        end
      end
    end
  end
end

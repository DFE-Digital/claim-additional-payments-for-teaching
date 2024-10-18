module Admin
  class FraudRiskCsvUploadForm
    include ActiveModel::Model

    attr_accessor :file

    validates :file, presence: {message: "CSV file is required"}

    validate :csv_has_required_headers, if: -> { file.present? }

    validate :all_rows_are_valid, if: -> { file.present? && csv_has_required_headers? }

    def initialize(params = {})
      super
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        RiskIndicator.where.not(id: records.map(&:id)).destroy_all

        records.each(&:save!)
      end

      true
    end

    private

    def csv
      @csv ||= CSV.parse(file.read, headers: true, skip_blanks: true)
    end

    def records
      @records ||= csv.map do |row|
        RiskIndicator.find_or_initialize_by(row.to_h)
      end.uniq { |record| record.attributes.slice("field", "value") }
    end

    def all_rows_are_valid
      csv.each do |row|
        unless RiskIndicator::SUPPORTED_FIELDS.include?(row["field"])
          errors.add(
            :base,
            "'#{row["field"]}' is not a valid attribute - " \
            "must be one of #{RiskIndicator::SUPPORTED_FIELDS.join(", ")}"
          )
        end

        if row["value"].blank?
          errors.add(:base, "'value' can't be blank")
        end
      end
    end

    def csv_has_required_headers
      unless csv_has_required_headers?
        errors.add(:base, "csv is missing required headers `field`, `value`")
      end
    end

    def csv_has_required_headers?
      csv.headers.include?("field") && csv.headers.include?("value")
    end
  end
end

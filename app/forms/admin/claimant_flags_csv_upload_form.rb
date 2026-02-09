module Admin
  class ClaimantFlagsCsvUploadForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :file

    attribute :admin

    validates(
      :file,
      presence: {
        message: "Choose a CSV file of flagged claimants to upload"
      }
    )

    validates :admin, presence: true

    validate :validate_all_rows_are_valid, if: -> { file.present? }

    def initialize(params)
      super
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        ClaimantFlag.delete_all

        csv.each do |row|
          policy = policies.fetch(row["policy"])

          ClaimantFlag.create!(
            policy: policy,
            identification_attribute: row["identification_attribute"],
            identification_value: row["identification_value"],
            reason: row["reason"],
            suggested_action: row["suggested_action"].presence
          )
        end
      end
    end

    private

    def csv
      @csv ||= CSV.parse(file.read.chomp, headers: true)
    end

    def validate_all_rows_are_valid
      csv.each_with_index do |row, index|
        validate_row(row, index + 1)
      end
    end

    def policies
      @policies ||= Policies.all.index_by(&:to_s)
    end

    def validate_row(row, row_index)
      policy_name = row["policy"]
      policy = policies[policy_name]
      identification_attribute = row["identification_attribute"]
      identification_value = row["identification_value"]
      reason = row["reason"]

      if policy_name.blank?
        errors.add(:file, "Row #{row_index}: Policy is required")
      end

      if policy.nil?
        errors.add(:file, "Row #{row_index}: Invalid policy '#{policy_name}'")
      end

      if identification_attribute.blank?
        errors.add(:file, "Row #{row_index}: Identification attribute is required")
      end

      unless ClaimantFlag::IDENTIFICATION_ATTRIBUTES.include?(identification_attribute)
        errors.add(
          :file,
          "Row #{row_index}: Invalid identification attribute '#{identification_attribute}'"
        )
      end

      if identification_value.blank?
        errors.add(:file, "Row #{row_index}: Identification value is required")
      end

      unless ClaimantFlag.reasons.key?(reason)
        errors.add(:file, "Row #{row_index}: Invalid reason '#{reason}'")
      end
    end
  end
end

require "csv"

class Claim
  class DatabaseOfQualifiedTeachersReportRequest
    ATTRIBUTES = {
      reference: "Claim reference",
      teacher_reference_number: "Teacher reference number",
    }.freeze

    def initialize(claims)
      @claims = claims
    end

    def to_csv
      CSV.generate do |csv|
        csv << ATTRIBUTES.values

        @claims.each do |claim|
          csv << ATTRIBUTES.keys.map { |attribute| claim.read_attribute(attribute) }
        end
      end
    end
  end
end

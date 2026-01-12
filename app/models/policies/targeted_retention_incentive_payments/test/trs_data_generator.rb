require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class TrsDataGenerator
        HEADERS = %w[
          teacher_reference_number
          first_name
          last_name
          date_of_birth
          national_insurance_number
          qts_date
          induction_status
          route_type
          itt_subject_1
          itt_start_date
          itt_qualification_type
          active_alert
        ].freeze

        def self.data
          new.data
        end

        def self.to_csv
          new.to_csv
        end

        def self.to_file(file = nil)
          new.to_file(file:)
        end

        def data
          personas.map do |persona|
            [
              :teacher_reference_number,
              :first_name,
              :last_name,
              :date_of_birth,
              :national_insurance_number,
              :qts_date,
              :induction_status,
              :route_type,
              :itt_subject,
              :itt_start_date,
              :itt_qualification_type,
              :active_alert?
            ].map { |attribute| persona.send(attribute) }
          end
        end

        def to_csv
          rows = data.map { |record| CSV::Row.new(headers, record) }

          CSV::Table.new(
            rows,
            headers:
          )
        end

        def to_file(file: nil)
          file ||= Tempfile.new
          file.write(to_csv.to_s)
          file.rewind
          file
        end

        private

        def headers
          HEADERS
        end

        def personas
          @personas ||= UserPersona.all
        end
      end
    end
  end
end

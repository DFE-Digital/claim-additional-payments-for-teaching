require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class SchoolWorkforceCensusGenerator
        HEADERS = %w[
          teacher_reference_number
          school_urn
          contract_agreement_type
          totfte
          subject_description_sfr
          general_subject_code
          hours_taught
        ].freeze

        def self.data
          new.data
        end

        def self.to_csv
          new.to_csv
        end

        def self.to_file(file: nil)
          new.to_file(file:)
        end

        def data
          personas.map do |persona|
            SchoolWorkforceCensus.new(
              teacher_reference_number: persona.teacher_reference_number,
              school_urn: persona.school.urn,
              contract_agreement_type: nil, # not used
              totfte: nil, # not used
              subject_description_sfr: persona.teaching_subject,
              general_subject_code: nil, # not used
              hours_taught: nil # not used
            )
          end
        end

        def to_csv
          rows = data.map do |record|
            CSV::Row.new(headers, record.attributes.slice(*headers).values)
          end

          CSV::Table.new(
            rows,
            headers: []
          )
        end

        def to_file(file: nil)
          file ||= Tempfile.new
          file.write(to_csv.to_s(write_headers: false))
          file.rewind
          file
        end

        private

        def headers
          HEADERS
        end

        def personas
          @personas ||= UserPersona.eligible
        end
      end
    end
  end
end

require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class StriAwardsGenerator
        HEADERS = %w[
          school_urn
          award_amount
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
            school_name = persona.school_name
            school = School.find_by(name: school_name)

            Policies::TargetedRetentionIncentivePayments::Award.new(
              school_urn: school.urn,
              award_amount: 6000
            )
          end.uniq do |award|
            award.school_urn
          end
        end

        def to_csv
          rows = data.map do |record|
            CSV::Row.new(headers, record.attributes.slice("school_urn", "award_amount").values)
          end

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

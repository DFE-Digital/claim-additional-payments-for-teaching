require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class TeachersPensionsServiceGenerator
        HEADERS = [
          "Teacher reference number",
          "NINO",
          "Start Date",
          "End Date",
          "Employer ID",
          "LA URN",
          "School URN"
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

        def self.import!
          new.import!
        end

        def data
          personas.map do |persona|
            TeachersPensionsService.new(
              teacher_reference_number: persona.teacher_reference_number,
              nino: persona.national_insurance_number,
              school_urn: persona.school.establishment_number, # CSV School URN is School#establishment_number
              start_date:,
              end_date:,
              employer_id: nil, # not used
              la_urn: persona.school.local_authority.code
            )
          end
        end

        def to_csv
          fields = %w[
            teacher_reference_number
            national_insurance_number
            start_date
            end_date
            employer_id
            la_urn
            school_urn
          ]

          rows = data.map do |record|
            CSV::Row.new(headers, record.attributes.slice(*fields).values)
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

        def import!
          form = Admin::TpsDataForm.new({file: to_file}, DfeSignIn::User.first)
          form.run_import!
        end

        private

        def start_date
          Date.new(Policies::StudentLoans.current_academic_year.start_year, 4, 5)
        end

        def end_date
          previous_academic_year = Policies::StudentLoans.current_academic_year.previous
          Date.new(previous_academic_year.start_year, 4, 6)
        end

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

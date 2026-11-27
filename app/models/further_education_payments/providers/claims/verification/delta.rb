module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        # given 2 claims
        # figure out the similarities and differenaces
        class Delta
          attr_reader :a, :b, :changes

          # :provider_verification_teaching_start_year,
          #
          # :teaching_responsibilities,
          # :teaching_qualification,
          # :contract_type,
          # :teaching_hours_per_week,
          # :half_teaching_hours,
          #
          # t.boolean "hours_teaching_eligible_subjects"
          # :provider_verification_half_timetabled_teaching_time,
          #
          # fixed_term_full_year
          # :provider_verification_contract_covers_full_academic_year,
          #
          # taught_at_least_one_term
          # :provider_verification_taught_at_least_one_academic_term,
          #
          # t.boolean "subject_to_disciplinary_action"
          # :provider_verification_disciplinary_action,
          #
          # t.boolean "subject_to_formal_performance_action"
          # t.boolean "provider_verification_performance_measures"
          #

          def self.fields
            %w[
              building_construction_courses
            ]
          end

          def initialize(a:, b:)
            @a = a
            @b = b
          end

          # returns a hash
          # keys are fields that have changed
          # values are a 2 element array of before and after
          # if field has no change then will not be present in hash
          def changes
            return @changes if @changes

            hash = {}

            self.class.fields.each do |field|
              if a_attributes[field] != b_attributes[field]
                hash[field] = [a_attributes[field], b_attributes[field]]
              end
            end

            @changes = hash.with_indifferent_access
          end

          private

          def a_attributes
            @a_attributes ||= a.eligibility.attributes.slice(*self.class.fields)
          end

          def b_attributes
            @b_attributes ||= b.eligibility.attributes.slice(*self.class.fields)
          end
        end
      end
    end
  end
end

module Policies
  module EarlyCareerPayments
    class Eligibility < ApplicationRecord
      include Eligible
      include EligibilityCheckable

      AMENDABLE_ATTRIBUTES = [:award_amount].freeze
      ATTRIBUTE_DEPENDENCIES = {
        "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
        "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
        "eligible_itt_subject" => ["teaching_subject_now"],
        "itt_academic_year" => ["eligible_itt_subject"]
      }.freeze

      IGNORED_ATTRIBUTES = [
        "eligible_degree_subject"
      ]

      self.table_name = "early_career_payments_eligibilities"

      FIRST_ITT_AY = "2016/2017"
      LAST_POLICY_YEAR = "2024/2025"

      # Generates an object similar to
      # {
      #   <AcademicYear:0x00007f7d87429238 @start_year=2020, @end_year=2021> => "2020/2021",
      #   <AcademicYear:0x00007f7d87429210 @start_year=2021, @end_year=2022> => "2021/2022",
      #   <AcademicYear:0x00007f7d87428c98 @start_year=nil, @end_year=nil> => "None"
      # }
      # Note: ECP policy began in academic year 2021/22 so the persisted options
      # should include 2016/17 onward.
      # In test environment the journey configuration record may not exist.
      # This can't be dynamic on Journeys::Configuration current_academic_year because changing the year means the 5 year window changes
      # and the enums would be stale until after a server restart.
      # Make all valid ITT values based on the last known policy year.
      ITT_ACADEMIC_YEARS =
        (AcademicYear.new(FIRST_ITT_AY)...AcademicYear.new(LAST_POLICY_YEAR)).each_with_object({}) do |year, hsh|
          hsh[year] = AcademicYear::Type.new.serialize(year)
        end.merge({AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)})

      enum itt_academic_year: ITT_ACADEMIC_YEARS

      enum qualification: {
        postgraduate_itt: 0,
        undergraduate_itt: 1,
        assessment_only: 2,
        overseas_recognition: 3
      }

      enum eligible_itt_subject: {
        chemistry: 0,
        foreign_languages: 1,
        mathematics: 2,
        physics: 3,
        none_of_the_above: 4,
        computing: 5
      }, _prefix: :itt_subject

      def self.max_award_amount_in_pounds
        Policies::EarlyCareerPayments::AwardAmountCalculator.max_award_amount_in_pounds
      end

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, optional: true, class_name: "School"

      validates :current_school, on: [:"correct-school"], presence: {message: "Select the school you teach at or choose somewhere else"}, unless: :school_somewhere_else?
      validates_numericality_of :award_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 7500
      validates :award_amount, on: :amendment, award_range: {max: max_award_amount_in_pounds}

      delegate :name, to: :current_school, prefix: true, allow_nil: true

      delegate :academic_year, to: :claim

      def award_amount
        super || BigDecimal(calculate_award_amount || 0)
      end

      # Rescues from errors for assignments coming from LUP-only fields
      # eg. `claim.eligibility.eligible_degree_subject = true` will get ignored
      def assign_attributes(*args, **kwargs)
        super
      rescue ActiveRecord::UnknownAttributeError
        all_attributes_ignored = (args.first.keys - IGNORED_ATTRIBUTES).empty?
        raise unless all_attributes_ignored
      end

      def reset_dependent_answers(reset_attrs = [])
        attrs = ineligible? ? changed.concat(reset_attrs) : changed

        dependencies = ATTRIBUTE_DEPENDENCIES.dup

        # If some data was derived from DQT we do not want to reset these.
        if claim.qualifications_details_check
          dependencies.delete("qualification")
          dependencies.delete("eligible_itt_subject")
          dependencies.delete("itt_academic_year")
        end

        dependencies.each do |attribute_name, dependent_attribute_names|
          dependent_attribute_names.each do |dependent_attribute_name|
            write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
          end
        end
      end
    end
  end
end

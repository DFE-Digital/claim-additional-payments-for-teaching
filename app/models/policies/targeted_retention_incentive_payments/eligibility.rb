module Policies
  module TargetedRetentionIncentivePayments
    class Eligibility < ApplicationRecord
      include TeacherReferenceNumberValidation

      def policy
        Policies::TargetedRetentionIncentivePayments
      end

      include ActiveSupport::NumberHelper

      self.table_name = "targeted_retention_incentive_payments_eligibilities"
      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, optional: true, class_name: "School"

      before_validation :normalise_teacher_reference_number, if: :teacher_reference_number_changed?

      validate :award_amount_must_be_in_range, on: :amendment
      validates :teacher_reference_number, on: :amendment, presence: {message: "Enter your teacher reference number"}
      validate :validate_teacher_reference_number_length

      delegate :name, to: :current_school, prefix: true, allow_nil: true

      AMENDABLE_ATTRIBUTES = [:teacher_reference_number, :award_amount].freeze

      FIRST_ITT_AY = "2017/2018"

      # Generates an object similar to
      # {
      #   <AcademicYear:0x00007f7d87429238 @start_year=2020, @end_year=2021> => "2020/2021",
      #   <AcademicYear:0x00007f7d87429210 @start_year=2021, @end_year=2022> => "2021/2022",
      #   <AcademicYear:0x00007f7d87428c98 @start_year=nil, @end_year=nil> => "None"
      # }
      # Note: Targeted Retention Incentive policy began in academic year 2022/23 so the persisted options
      # should include 2017/18 onward.
      # In test environment the journey configuration record may not exist.
      # This can't be dynamic on Journeys::Configuration current_academic_year because changing the year means the 5 year window changes
      # and the enums would be stale until after a server restart.
      # Make all valid ITT values based on the last known policy year.
      ITT_ACADEMIC_YEARS =
        (AcademicYear.new(FIRST_ITT_AY)...POLICY_END_YEAR).each_with_object({}) do |year, hsh|
          hsh[year] = AcademicYear::Type.new.serialize(year)
        end.merge({AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)})

      enum :itt_academic_year, ITT_ACADEMIC_YEARS

      enum :qualification, {
        postgraduate_itt: 0,
        undergraduate_itt: 1,
        assessment_only: 2,
        overseas_recognition: 3
      }

      enum :eligible_itt_subject, {
        chemistry: 0,
        foreign_languages: 1,
        mathematics: 2,
        physics: 3,
        none_of_the_above: 4,
        computing: 5
      }, prefix: :itt_subject

      # NOTE - remove once string column is renamed
      def qualification=(value)
        normalised_value = if value.is_a?(Integer)
          self.class.qualifications.invert[value].to_s
        else
          value.to_s
        end

        self.qualification_string = normalised_value

        super
      end

      # NOTE - remove once string column is renamed
      def eligible_itt_subject=(value)
        normalised_value = if value.is_a?(Integer)
          self.class.eligible_itt_subjects.invert[value].to_s
        else
          value.to_s
        end

        self.eligible_itt_subject_string = normalised_value

        super
      end

      private

      def award_amount_must_be_in_range
        claim_year = policy.current_academic_year
        max = TargetedRetentionIncentivePayments::Award.by_academic_year(claim_year).maximum(:award_amount)

        unless award_amount&.between?(1, max)
          errors.add(:award_amount, "Enter a positive amount up to #{number_to_currency(max)} (inclusive)")
        end
      end
    end
  end
end

module Policies
  module EarlyCareerPayments
    class Eligibility < ApplicationRecord
      include TeacherReferenceNumberValidation

      def policy
        Policies::EarlyCareerPayments
      end

      AMENDABLE_ATTRIBUTES = []

      IGNORED_ATTRIBUTES = [
        "eligible_degree_subject"
      ]

      self.table_name = "early_career_payments_eligibilities"

      FIRST_ITT_AY = "2016/2017"

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
        (AcademicYear.new(FIRST_ITT_AY)...POLICY_END_YEAR).each_with_object({}) do |year, hsh|
          hsh[year] = AcademicYear::Type.new.serialize(year)
        end.merge({AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)})

      enum :itt_academic_year, ITT_ACADEMIC_YEARS, validate: true

      enum :qualification, %w[
        postgraduate_itt
        undergraduate_itt
        assessment_only
        overseas_recognition
      ].index_with(&:itself)

      enum :eligible_itt_subject, %w[
        chemistry
        foreign_languages
        mathematics
        physics
        none_of_the_above
        computing
      ].index_with(&:itself), prefix: :itt_subject

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, optional: true, class_name: "School"

      before_validation :normalise_teacher_reference_number, if: :teacher_reference_number_changed?

      validates :current_school, on: [:"correct-school"], presence: {message: "Select the school you teach at or choose somewhere else"}, unless: :school_somewhere_else?

      validates :teacher_reference_number, on: :amendment, presence: {message: "Enter your teacher reference number"}
      validate :validate_teacher_reference_number_length

      delegate :name, to: :current_school, prefix: true, allow_nil: true

      delegate :academic_year, to: :claim

      # Rescues from errors for assignments coming from Targeted Retention Incentive-only fields
      # eg. `claim.eligibility.eligible_degree_subject = true` will get ignored
      def assign_attributes(*args, **kwargs)
        super
      rescue ActiveRecord::UnknownAttributeError
        all_attributes_ignored = (args.first.keys - IGNORED_ATTRIBUTES).empty?
        raise unless all_attributes_ignored
      end
    end
  end
end

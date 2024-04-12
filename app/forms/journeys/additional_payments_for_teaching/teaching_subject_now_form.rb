module Journeys
  module AdditionalPaymentsForTeaching
    class TeachingSubjectNowForm < Form
      attribute :teaching_subject_now, :boolean

      validates :teaching_subject_now,
        inclusion: {
          in: [true, false],
          message: "Select yes if you spend at least half of your contracted hours teaching eligible subjects"
        }

      def initialize(journey:, claim:, params:)
        super

        self.teaching_subject_now = permitted_params.fetch(
          :teaching_subject_now,
          claim.eligibility.teaching_subject_now
        )
      end

      def eligible_itt_subject
        @eligible_itt_subject ||= claim.eligibility.eligible_itt_subject
      end

      def teaching_physics_or_chemistry?
        eligible_itt_subject == "physics" || eligible_itt_subject == "chemistry"
      end

      def save
        return false unless valid?

        update!(
          eligibility_attributes: {
            teaching_subject_now: teaching_subject_now
          }
        )
      end
    end
  end
end

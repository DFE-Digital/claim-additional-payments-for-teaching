module Journeys
  module AdditionalPaymentsForTeaching
    class TeachingSubjectNowForm < Form
      attribute :teaching_subject_now, :boolean

      validates :teaching_subject_now, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def eligible_itt_subject
        @eligible_itt_subject ||= claim.eligibility.eligible_itt_subject
      end

      def teaching_physics_or_chemistry?
        eligible_itt_subject == "physics" || eligible_itt_subject == "chemistry"
      end

      # FIXME RL: Once this method writes to the journey session answers update
      # QualificationForm#save to not reset teaching subject on the claim, as
      # it's no longer needed (still keep resetting it on the answers)
      # (and remove this comment!)
      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end

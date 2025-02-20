module Journeys
  module TargetedRetentionIncentivePayments
    class NqtInAcademicYearAfterIttForm < Form
      attribute :nqt_in_academic_year_after_itt, :boolean

      validates :nqt_in_academic_year_after_itt, inclusion: {
        in: [true, false],
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          set_qualification! if trainee_teacher?

          journey_session.answers.assign_attributes(
            induction_completed: determine_induction_answer_from_dqt_record,
            nqt_in_academic_year_after_itt:
          )
          journey_session.save
        end
      end

      private

      def trainee_teacher?
        nqt_in_academic_year_after_itt == false
      end

      # FIXME RL - will want to change this to use the lup dqt teacher record,
      # we can name the method SessionAnswers#dqt_teacher_record
      # will deal with this once we do the teacher id sign in feature,
      # for now will just leave this as is
      def determine_induction_answer_from_dqt_record
        return unless passed_details_check_with_teacher_id?
        # We can derive the induction_completed value for current_claim using the
        # ECP DQT record Remember: even if it's only relevant to ECP, the induction
        # question is asked at the beginning of the combined journey, and the
        # applicant may end up applying for ECP or Targeted Retention Incentive only at a later stage in
        # the journey, hence we need to store the answer on both eligibilities.
        journey_session.answers.early_career_payments_dqt_teacher_record&.eligible_induction?
      end

      def passed_details_check_with_teacher_id?
        journey_session.answers.passed_details_check_with_teacher_id?
      end

      # We can't just update the eligibility's qualification as there's
      # dependent answers that need reseting, so we go through the
      # qualification form to make sure that's all handled in one place
      def set_qualification!
        # FIXME RL - to do, will enable this once I've copied over the
        # qualification form
        # QualificationForm.new(
        #  journey: journey,
        #  journey_session: journey_session,
        #  params: ActionController::Parameters.new(
        #    claim: {
        #      qualification: :postgraduate_itt
        #    }
        #  )
        # ).save!
      end
    end
  end
end

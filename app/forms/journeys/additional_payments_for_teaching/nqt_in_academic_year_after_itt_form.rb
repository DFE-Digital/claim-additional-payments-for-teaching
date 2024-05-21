module Journeys
  module AdditionalPaymentsForTeaching
    class NqtInAcademicYearAfterIttForm < Form
      include EligibilityCheckable

      attribute :nqt_in_academic_year_after_itt, :boolean

      validates :nqt_in_academic_year_after_itt, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          set_qualification! if trainee_teacher?

          update!(
            {
              eligibility_attributes: {
                nqt_in_academic_year_after_itt: nqt_in_academic_year_after_itt,
                induction_completed: determine_induction_answer_from_dqt_record
              }
            }
          )
        end
      end

      def backlink_path
        return unless page_sequence.in_sequence?("correct-school")

        Rails
          .application
          .routes
          .url_helpers
          .claim_path(params[:journey], "correct-school")
      end

      private

      def determine_induction_answer_from_dqt_record
        return unless passed_details_check_with_teacher_id?
        # We can derive the induction_completed value for current_claim using the
        # ECP DQT record Remember: even if it's only relevant to ECP, the induction
        # question is asked at the beginning of the combined journey, and the
        # applicant may end up applying for ECP or LUPP only at a later stage in
        # the journey, hence we need to store the answer on both eligibilities.
        journey_session.answers.ecp_dqt_teacher_record&.eligible_induction?
      end

      def passed_details_check_with_teacher_id?
        journey_session.answers.passed_details_check_with_teacher_id?
      end

      # We can't just update the eligibility's qualification as there's
      # dependent answers that need reseting, so we go through the
      # qualification form to make sure that's all handled in one place
      def set_qualification!
        QualificationForm.new(
          journey: journey,
          journey_session: journey_session,
          claim: claim,
          params: ActionController::Parameters.new(
            claim: {
              qualification: :postgraduate_itt
            }
          )
        ).save!
      end
    end
  end
end

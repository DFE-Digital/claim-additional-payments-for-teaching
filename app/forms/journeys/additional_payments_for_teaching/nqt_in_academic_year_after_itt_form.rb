module Journeys
  module AdditionalPaymentsForTeaching
    class NqtInAcademicYearAfterIttForm < Form
      include EligibilityCheckable

      attribute :nqt_in_academic_year_after_itt, :boolean

      validates :nqt_in_academic_year_after_itt,
        inclusion: {
          in: [true, false],
          message: "Select yes if you are currently teaching as a qualified teacher"
        }

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

      def permitted_params
        @permitted_params ||= params.fetch(:claim, {}).permit(
          :nqt_in_academic_year_after_itt
        )
      end

      def determine_induction_answer_from_dqt_record
        return unless passed_details_check_with_teacher_id?
        # We can derive the induction_completed value for current_claim using the
        # ECP DQT record Remember: even if it's only relevant to ECP, the induction
        # question is asked at the beginning of the combined journey, and the
        # applicant may end up applying for ECP or LUPP only at a later stage in
        # the journey, hence we need to store the answer on both eligibilities.
        claim_for_policy = claim.for_policy(Policies::EarlyCareerPayments)
        dqt_teacher_record = claim_for_policy.dqt_teacher_record
        dqt_teacher_record&.eligible_induction?
      end

      def passed_details_check_with_teacher_id?
        claim.logged_in_with_tid? && claim.details_check?
      end

      # We can't just update the eligibility's qualification as there's
      # dependent answers that need reseting, so we go through the
      # qualification form to make sure that's all handled in one place
      def set_qualification!
        QualificationForm.new(
          journey: journey,
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

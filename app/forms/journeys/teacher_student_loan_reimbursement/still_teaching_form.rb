module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingForm < Form
      attribute :employment_status
      attribute :current_school_id

      validates :employment_status,
        presence: {
          message: ->(form, _) { form.i18n_errors_path("select_which_school_currently", school_name: form.claim_school_name) }
        }

      delegate :logged_in_with_tid_and_has_recent_tps_school?, to: :claim

      def save
        return false unless valid?

        update!(
          eligibility_attributes: {
            employment_status:,
            current_school_id: at_claim_school? ? current_school_id : nil
          }
        )
      end

      def claim_school_name
        claim.eligibility.claim_school_name
      end

      def tps_or_claim_school
        logged_in_with_tid_and_has_recent_tps_school? ? "tps_school" : "claim_school"
      end

      private

      def at_claim_school?
        %w[claim_school recent_tps_school].include?(employment_status)
      end
    end
  end
end

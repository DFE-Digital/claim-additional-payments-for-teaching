module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingForm < Form
      attribute :employment_status
      attribute :current_school_id

      validates :employment_status,
        presence: {
          message: ->(object, _) { "Select if you still work at #{object.claim.eligibility.claim_school_name}, another school or no longer teach in England" }
        }

      def save
        return false unless valid?

        update!(
          eligibility_attributes: {
            employment_status:,
            current_school_id: %w[claim_school recent_tps_school].include?(employment_status) ? current_school_id : nil
          }
        )
      end
    end
  end
end

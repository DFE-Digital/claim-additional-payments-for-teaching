module Journeys
  module TeacherStudentLoanReimbursement
    class LeadershipPositionForm < Form
      attribute :had_leadership_position, :boolean

      validates :had_leadership_position,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("inclusion") }
        }

      def save
        return false unless valid?
        return true unless had_leadership_position_changed?

        update!(
          eligibility_attributes: {
            had_leadership_position: had_leadership_position,
            mostly_performed_leadership_duties: nil
          }
        )
      end

      private

      def had_leadership_position_changed?
        claim.eligibility.had_leadership_position != had_leadership_position
      end
    end
  end
end

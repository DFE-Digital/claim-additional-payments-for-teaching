module Journeys
  module TeacherStudentLoanReimbursement
    class QualificationDetailsForm < Form
      attribute :qualifications_details_check, :boolean

      validates :qualifications_details_check,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("qualifications_details_check") }
        }

      def dqt_qts_award_date
        AcademicYear.for(answers.dqt_teacher_record.qts_award_date)
      end

      def save
        return false unless valid?

        update!(qualifications_details_check: qualifications_details_check)

        journey_session.answers.assign_attributes(
          qts_award_year: qts_award_year
        )

        journey_session.save!
      end

      private

      def qts_award_year
        # Teacher has said the details don't match what they expected so
        # nullify them
        return nil unless qualifications_details_check

        return nil unless answers.dqt_teacher_record&.qts_award_date

        if answers.dqt_teacher_record.eligible_qts_award_date?
          :on_or_after_cut_off_date
        else
          :before_cut_off_date
        end
      end
    end
  end
end

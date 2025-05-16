module Journeys
  module TargetedRetentionIncentivePayments
    class NqtInAcademicYearAfterIttForm < Form
      attribute :nqt_in_academic_year_after_itt, :boolean

      validates :nqt_in_academic_year_after_itt, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          set_qualification! if trainee_teacher?

          journey_session.answers.assign_attributes(
            nqt_in_academic_year_after_itt:
          )
          journey_session.save
        end
      end

      def radio_options
        [
          Option.new(id: true, name: t("options.true")),
          Option.new(id: false, name: t("options.false"))
        ]
      end

      private

      def trainee_teacher?
        nqt_in_academic_year_after_itt == false
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

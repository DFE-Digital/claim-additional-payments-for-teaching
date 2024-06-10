module Journeys
  module AdditionalPaymentsForTeaching
    class QualificationForm < Form
      QUALIFICATION_OPTIONS = %w[
        postgraduate_itt
        undergraduate_itt
        assessment_only
        overseas_recognition
      ].freeze

      attribute :qualification, :string

      validates :qualification, inclusion: {in: QUALIFICATION_OPTIONS, message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?
        return true unless qualification_changed?

        journey_session.answers.assign_attributes(qualification: qualification)

        # If some data was derived from DQT we do not want to reset these.
        unless answers.qualifications_details_check
          # Once the teaching_subject_now and eligible_itt_subject forms are
          # writing to the answers we can remove this claim update
          claim.update!(eligibility_attributes: {eligible_itt_subject: nil})

          journey_session.answers.assign_attributes(
            eligible_itt_subject: nil,
            teaching_subject_now: nil
          )
        end

        journey_session.save!

        true
      end

      def save!
        raise ActiveRecord::RecordInvalid.new unless save
      end

      private

      def qualification_changed?
        answers.qualification != qualification
      end
    end
  end
end

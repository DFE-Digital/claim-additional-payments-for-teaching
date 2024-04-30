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

        if claim.qualifications_details_check?
          update!(
            eligibility_attributes: {
              qualification: qualification
            }
          )
        else
          update!(
            eligibility_attributes: {
              qualification: qualification,
              eligible_itt_subject: nil,
              teaching_subject_now: nil
            }
          )
        end

        true
      end

      def save!
        raise ActiveRecord::RecordInvalid.new unless save
      end

      private

      def qualification_changed?
        claim.eligibility.qualification != qualification
      end
    end
  end
end

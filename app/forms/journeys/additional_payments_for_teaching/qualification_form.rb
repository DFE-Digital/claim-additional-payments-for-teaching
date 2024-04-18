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

      validates :qualification,
        inclusion: {
          in: QUALIFICATION_OPTIONS,
          message: "Select the route you took into teaching"
        }

      def save
        return false unless valid?

        # We set the attribute like this, rather than using `update!` from the
        # superclass, as we need "qualification" to be in the `Eligibility#changed`
        # list of attributes for the `reset_dependent_answers` method to work
        claim.assign_attributes(
          eligibility_attributes: {qualification: qualification}
        )
        claim.reset_eligibility_dependent_answers(["qualification"])
        claim.save!

        true
      end

      def save!
        raise ActiveRecord::RecordInvalid.new unless save
      end
    end
  end
end

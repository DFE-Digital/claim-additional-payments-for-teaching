module Journeys
  module AdditionalPaymentsForTeaching
    class SupplyTeacherForm < Form
      attribute :employed_as_supply_teacher, :boolean

      validates :employed_as_supply_teacher, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        if employed_as_supply_teacher_changed?
          journey_session.answers.assign_attributes(
            has_entire_term_contract: nil,
            employed_directly: nil
          )

          journey_session.save!
        end

        update!(eligibility_attributes: attributes)
      end

      private

      # FIXME RL: Once this form is writing to the session update this check to
      # use the session
      def employed_as_supply_teacher_changed?
        claim.eligibility.employed_as_supply_teacher != employed_as_supply_teacher
      end
    end
  end
end

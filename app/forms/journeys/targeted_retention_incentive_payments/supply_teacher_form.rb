module Journeys
  module TargetedRetentionIncentivePayments
    class SupplyTeacherForm < Form
      attribute :employed_as_supply_teacher, :boolean

      validates :employed_as_supply_teacher, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?
        return true unless employed_as_supply_teacher_changed?

        journey_session.answers.assign_attributes(
          employed_as_supply_teacher: employed_as_supply_teacher,
          has_entire_term_contract: nil,
          employed_directly: nil
        )

        journey_session.save!
      end

      def radio_options
        [
          Option.new(id: true, name: t("options.true")),
          Option.new(id: false, name: t("options.false"))
        ]
      end

      private

      def employed_as_supply_teacher_changed?
        answers.employed_as_supply_teacher != employed_as_supply_teacher
      end
    end
  end
end

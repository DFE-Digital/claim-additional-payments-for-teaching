module Journeys
  module FurtherEducationPayments
    class TeachingQualificationForm < Form
      attribute :teaching_qualification, :string

      validates :teaching_qualification,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        [
          Option.new(
            id: "yes",
            name: t("options.yes")
          ),
          Option.new(
            id: "not_yet",
            name: t("options.not_yet")
          ),
          Option.new(
            id: "no_but_planned",
            name: t("options.no_but_planned")
          ),
          Option.new(
            id: "no_not_planned",
            name: t("options.no_not_planned")
          )
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(teaching_qualification:)
        journey_session.save!
      end
    end
  end
end

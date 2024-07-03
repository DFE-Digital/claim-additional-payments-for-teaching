module Journeys
  module FurtherEducationPayments
    class TeachingQualificationForm < Form
      attribute :teaching_qualification, :string

      validates :teaching_qualification,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        [
          OpenStruct.new(
            id: "yes",
            name: "Yes"
          ),
          OpenStruct.new(
            id: "not-yet",
            name: "Not yet, I am currently enrolled on one and working towards completing it"
          ),
          OpenStruct.new(
            id: "no-but-planned",
            name: "No, but I plan to enrol on one in the next 12 months"
          ),
          OpenStruct.new(
            id: "no-not-planned",
            name: "No, and I do not plan to enrol on one in the next 12 months "
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

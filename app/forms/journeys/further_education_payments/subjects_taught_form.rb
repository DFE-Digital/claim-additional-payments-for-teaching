module Journeys
  module FurtherEducationPayments
    class SubjectsTaughtForm < Form
      include ActiveModel::Validations::Callbacks

      attribute :subjects_taught, default: []

      before_validation :clean_subjects_taught

      validates :subjects_taught,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        [
          OpenStruct.new(id: "building-and-construction", name: "Building and construction"),
          OpenStruct.new(id: "chemistry", name: "Chemistry"),
          OpenStruct.new(id: "computing", name: "Computing, including digital and ICT"),
          OpenStruct.new(id: "early-years", name: "Early years"),
          OpenStruct.new(id: "engineering-and-manufacturing", name: "Engineering and manufacturing, including transport engineering and electronics"),
          OpenStruct.new(id: "mathematics", name: "Mathematics"),
          OpenStruct.new(id: "physics", name: "Physics"),
          OpenStruct.new(id: "none", name: "I do not teach any of these subjects")
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(subjects_taught:)
        journey_session.save!
      end

      private

      def clean_subjects_taught
        subjects_taught.reject!(&:blank?)
      end
    end
  end
end

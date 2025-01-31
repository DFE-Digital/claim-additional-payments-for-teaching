module Journeys
  module FurtherEducationPayments
    class SubjectsTaughtForm < Form
      include ActiveModel::Validations::Callbacks
      include CoursesHelper

      attribute :subjects_taught, default: []

      before_validation :clean_subjects_taught

      validates :subjects_taught,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def checkbox_options
        (ALL_SUBJECTS + ["none"]).map { |subject| OpenStruct.new(id: subject, name: t("options.#{subject}")) }
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(subjects_taught:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(subjects_taught: [])
        journey_session.save!
      end

      private

      def clean_subjects_taught
        subjects_taught.reject!(&:blank?)
      end
    end
  end
end

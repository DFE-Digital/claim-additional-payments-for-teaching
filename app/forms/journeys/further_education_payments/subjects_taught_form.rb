module Journeys
  module FurtherEducationPayments
    class SubjectsTaughtForm < Form
      include ActiveModel::Validations::Callbacks

      attribute :subjects_taught, default: []

      before_validation :clean_subjects_taught

      validates :subjects_taught,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def checkbox_options
        [
          OpenStruct.new(id: "building_construction", name: t("options.building_and_construction")),
          OpenStruct.new(id: "chemistry", name: t("options.chemistry")),
          OpenStruct.new(id: "computing", name: t("options.computing")),
          OpenStruct.new(id: "early_years", name: t("options.early_years")),
          OpenStruct.new(id: "engineering_manufacturing", name: t("options.engineering_and_manufacturing")),
          OpenStruct.new(id: "maths", name: t("options.maths")),
          OpenStruct.new(id: "physics", name: t("options.physics")),
          OpenStruct.new(id: "none", name: t("options.none"))
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

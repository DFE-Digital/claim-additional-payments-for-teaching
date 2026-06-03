module Feedbacks
  class DetailsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :rating, :string
    attribute :area, :string
    attribute :specific_page, :string
    attribute :comment, :string
    attribute :research_participation, :boolean
    attribute :email_address, :string
    attribute :occupation, :string
    attribute :origin, :string
    attribute :claim_id, :string

    def self.i18n_error_message(path, args = {})
      ->(object, _) { object.i18n_errors_path(path, args) }
    end

    def i18n_errors_path(key, args = {})
      base_key = :"forms.#{i18n_form_namespace}.errors.#{key}"
      I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
    end

    def i18n_form_namespace
      self.class.name.demodulize.gsub("Form", "").underscore
    end

    def i18n_namespace
      "early_years_teachers_financial_incentive_payments"
    end

    validates :rating,
      inclusion: {
        in: ->(form) { form.rating_radio_options.map(&:id) },
        message: i18n_error_message(:rating_inclusion)
      }

    validates :area,
      inclusion: {
        in: ->(form) { form.area_radio_options.map(&:id) },
        message: i18n_error_message(:area_inclusion)
      }

    validates :specific_page,
      inclusion: {
        in: ->(form) { form.specific_page_radio_options.map(&:id) },
        message: i18n_error_message(:specific_page_inclusion),
        if: ->(form) { form.area == "specific_page" }
      }

    validates :comment,
      length: {
        maximum: 1_250,
        message: i18n_error_message(:comment_length)
      }

    validates :research_participation,
      inclusion: {
        in: [true, false],
        message: i18n_error_message(:research_participation_inclusion)
      }

    validates :email_address,
      presence: {
        message: i18n_error_message(:email_address_presence),
        if: ->(form) { form.research_participation }
      }

    validates :occupation,
      presence: {
        message: i18n_error_message(:occupation_presence),
        if: ->(form) { form.research_participation }
      }

    def rating_radio_options
      [
        Form::Option.new(
          id: "very_satisfied",
          name: "Very satisfied"
        ),
        Form::Option.new(
          id: "satisfied",
          name: "Satisfied"
        ),
        Form::Option.new(
          id: "neither",
          name: "Neither satisfied or dissatisfied"
        ),
        Form::Option.new(
          id: "dissatisfied",
          name: "Dissatisfied"
        ),
        Form::Option.new(
          id: "very_dissatisfied",
          name: "Very dissatisfied"
        )
      ]
    end

    def area_radio_options
      [
        Form::Option.new(
          id: "whole_service",
          name: "Whole service"
        ),
        Form::Option.new(
          id: "specific_page",
          name: "Specific page"
        )
      ]
    end

    def specific_page_radio_options
      [
        Form::Option.new(
          id: "guidance",
          name: "Guidance"
        ),
        Form::Option.new(
          id: "nursery_selection",
          name: "Nursery selection"
        ),
        Form::Option.new(
          id: "uploading",
          name: "Uploading proof of employment"
        ),
        Form::Option.new(
          id: "bank_details",
          name: "Providing bank details"
        ),
        Form::Option.new(
          id: "submission",
          name: "Submission"
        )
      ]
    end

    def save
      return false if invalid?

      Feedback.create(
        rating:,
        area:,
        specific_page:,
        comment:,
        research_participation:,
        email_address:,
        occupation:,
        origin:,
        claim_id:
      )
    end
  end
end

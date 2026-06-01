module Feedbacks
  class DetailsForm < Form
    attribute :rating, :string
    attribute :area, :string
    attribute :specific_page, :string
    attribute :comment, :string
    attribute :research_participation, :boolean
    attribute :email_address, :string
    attribute :occupation, :string
    attribute :origin, :string
    attribute :claim_id, :string

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
        Option.new(
          id: "very_satisfied",
          name: "Very satisfied"
        ),
        Option.new(
          id: "satisfied",
          name: "Satisfied"
        ),
        Option.new(
          id: "neither",
          name: "Neither satisfied or dissatisfied"
        ),
        Option.new(
          id: "dissatisfied",
          name: "Dissatisfied"
        ),
        Option.new(
          id: "very_dissatisfied",
          name: "Very dissatisfied"
        )
      ]
    end

    def area_radio_options
      [
        Option.new(
          id: "whole_service",
          name: "Whole service"
        ),
        Option.new(
          id: "specific_page",
          name: "Specific page"
        )
      ]
    end

    def specific_page_radio_options
      [
        Option.new(
          id: "guidance",
          name: "Guidance"
        ),
        Option.new(
          id: "nursery_selection",
          name: "Nursery selection"
        ),
        Option.new(
          id: "uploading",
          name: "Uploading proof of employment"
        ),
        Option.new(
          id: "bank_details",
          name: "Providing bank details"
        ),
        Option.new(
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

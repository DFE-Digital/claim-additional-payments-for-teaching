module Journeys
  module EarlyYearsTeachers
    module Provider
      class ProvideTeacherDetailsForm < Form
        attribute :teacher_id, :string
        attribute :teacher_full_name, :string
        attribute :teacher_email_address, :string
        attribute :teacher_mobile_phone_number, :string
        attribute :teacher_national_insurance_number, :string
        attribute :teacher_reference_number, :string

        attribute :remove_teacher, :boolean

        validates(
          :teacher_full_name,
          presence: {message: i18n_error_message("teacher_full_name.blank")}
        )

        validates(
          :teacher_email_address,
          presence: {message: i18n_error_message("teacher_email_address.blank")}
        )

        validates(
          :teacher_email_address,
          email_address_format: {
            message: i18n_error_message("teacher_email_address.invalid")
          },
          if: -> { teacher_email_address.present? }
        )

        validates(
          :teacher_mobile_phone_number,
          presence: {
            message: i18n_error_message("teacher_mobile_phone_number.blank")
          }
        )

        validates(
          :teacher_national_insurance_number,
          presence: {
            message: i18n_error_message("teacher_national_insurance_number.blank")
          }
        )

        validates(
          :teacher_reference_number,
          presence: {
            message: i18n_error_message("teacher_reference_number.blank")
          }
        )

        def save
          return false if invalid?

          details = {
            teacher_full_name: teacher_full_name,
            teacher_email_address: teacher_email_address,
            teacher_mobile_phone_number: teacher_mobile_phone_number,
            teacher_national_insurance_number: teacher_national_insurance_number,
            teacher_reference_number: teacher_reference_number
          }

          teacher_details = if editing?
            answers.teacher_details.map do |td|
              if td.with_indifferent_access[:teacher_id] == existing_teacher[:teacher_id]
                td.with_indifferent_access.merge(details)
              else
                td
              end
            end
          elsif removing_teacher?
            answers.teacher_details.reject do |td|
              td.with_indifferent_access[:teacher_id] == existing_teacher[:teacher_id]
            end
          else
            answers.teacher_details << details.merge(
              teacher_id: SecureRandom.uuid
            )
          end

          journey_session.answers.assign_attributes(
            teacher_details: teacher_details,
            teacher_details_form_completed: true
          )

          journey_session.save!
        end

        def completed?
          answers.teacher_details_form_completed?
        end

        def editing?
          existing_teacher.present? && !removing_teacher?
        end

        def removing_teacher?
          !!remove_teacher
        end

        private

        def load_current_value(attribute)
          existing_teacher.present? ? existing_teacher.fetch(attribute, nil) : nil
        end

        def existing_teacher
          @existing_teacher ||= answers
            .teacher_details
            .map(&:with_indifferent_access)
            .detect { |td| td[:teacher_id] == permitted_params[:teacher_id] }
        end
      end
    end
  end
end

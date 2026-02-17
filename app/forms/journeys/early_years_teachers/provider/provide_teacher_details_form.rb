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

          teacher = answers.current_teacher || answers.new_teacher

          teacher.assign_attributes(
            attributes
              .excluding("remove_teacher")
              .merge("performance_or_discipline" => nil)
          )

          if removing_teacher?
            teacher.destroy!
          else
            teacher.save!
          end

          journey_session.answers.assign_attributes(
            teacher_details: answers.teachers.map(&:attributes),
            teacher_details_form_completed: true,
            current_teacher_id: teacher.teacher_id,
            add_another_teacher: nil
          )

          journey_session.save!
        end

        def completed?
          answers.teacher_details_form_completed?
        end

        def removing_teacher?
          !!remove_teacher
        end

        private

        def current_teacher
          @current_teacher ||= answers.teachers.detect { |t| t.teacher_id == permitted_params["teacher_id"] }
        end

        def load_current_value(attribute)
          if current_teacher.present? && current_teacher.attribute_names.include?(attribute.to_s)
            current_teacher.public_send(attribute)
          end
        end
      end
    end
  end
end

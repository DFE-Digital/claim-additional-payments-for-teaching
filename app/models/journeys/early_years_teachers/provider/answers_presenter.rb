module Journeys
  module EarlyYearsTeachers
    module Provider
      class AnswersPresenter < BaseAnswersPresenter
        def nursery_answers
          [].tap do |a|
            a << provider_email_address_answer
            a << nursery_name_answer
            a << nursery_address_answer
            a << ofsted_urn_answer
            a << provider_status_answer
            a << nursery_type_answer
            a << nursery_subtype_answer
            a << employer_paye_reference_answer
            a << organisation_email_address_answer
          end
        end

        def manage_teachers_answers
          [].tap do |a|
            a << add_another_teacher_answer
          end
        end

        def teachers_answers
          answers.teachers.map do |teacher|
            answers_for_teacher(teacher)
          end
        end

        private

        def provider_email_address_answer
          [
            "Contact email address",
            answers.provider_email_address,
            "provider-email-address"
          ]
        end

        def nursery_name_answer
          [
            "Nursery name",
            answers.nursery_name,
            "update-nursery-details"
          ]
        end

        def nursery_address_answer
          address = [
            answers.nursery_address_line_1,
            answers.nursery_address_city,
            answers.nursery_address_postcode
          ].compact.join("<br>").html_safe

          [
            "Address",
            address,
            "update-nursery-details"
          ]
        end

        def ofsted_urn_answer
          [
            "Ofsted URN",
            answers.ofsted_urn,
            "update-nursery-details"
          ]
        end

        def provider_status_answer
          [
            "Provider status",
            answers.provider_status.humanize,
            "update-nursery-details"
          ]
        end

        def nursery_type_answer
          [
            "Nursery type",
            answers.nursery_type.humanize,
            "check-nursery-details"
          ]
        end

        def nursery_subtype_answer
          [
            "Nursery subtype",
            answers.nursery_subtype.humanize,
            "update-nursery-details"
          ]
        end

        def employer_paye_reference_answer
          [
            "Employer PAYE reference",
            answers.employer_paye_reference,
            "employer-paye-reference"
          ]
        end

        def organisation_email_address_answer
          [
            "Organisation email address",
            answers.organisation_email_address,
            "organisation-email-address"
          ]
        end

        def add_another_teacher_answer
          [
            "Add another teacher",
            answers.add_another_teacher ? "Yes" : "No",
            "manage-teachers"
          ]
        end
      end
    end
  end
end

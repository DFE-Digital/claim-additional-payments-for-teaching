module Journeys
  module EarlyYearsTeachers
    module Provider
      class TeacherNotEligibleForm < Form
        def completed?
          false
        end

        def save
          answers.current_teacher.destroy!

          journey_session.answers.assign_attributes(
            current_teacher_id: nil,
            teacher_details: answers.teachers.map(&:attributes)
          )

          journey_session.save!
        end

        def teacher_name
          answers.current_teacher&.teacher_full_name || "this teacher"
        end

        def teacher_id
          answers.current_teacher_id
        end

        def teacher
          answers.current_teacher
        end

        def edit_teacher_path
          Rails.application.routes.url_helpers.claim_path(
            Journeys::EarlyYearsTeachers::Provider::ROUTING_NAME,
            "provide-teacher-details",
            model_name.param_key => {teacher_id: answers.current_teacher_id}
          )
        end
      end
    end
  end
end

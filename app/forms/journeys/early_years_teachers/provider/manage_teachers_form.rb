module Journeys
  module EarlyYearsTeachers
    module Provider
      class ManageTeachersForm < Form
        attribute :add_another_teacher, :boolean

        validates(
          :add_another_teacher,
          inclusion: {
            in: [true, false],
            message: i18n_error_message("add_another_teacher.invalid")
          }
        )

        validate :at_least_one_teacher

        def radio_options
          [
            Option.new(id: true, name: "Yes"),
            Option.new(id: false, name: "No")
          ]
        end

        def teacher_count
          answers.teacher_details.count
        end

        def teachers
          answers.teachers
        end

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            add_another_teacher: add_another_teacher,
            teacher_details_form_completed: !add_another_teacher
          )
          journey_session.save!
        end

        def completed?
          valid? && answers.add_another_teacher == false
        end

        private

        def at_least_one_teacher
          if teacher_count.zero? && add_another_teacher == false
            errors.add(
              :add_another_teacher,
              t(%w[errors add_another_teacher at_least_one_teacher])
            )
          end
        end
      end
    end
  end
end

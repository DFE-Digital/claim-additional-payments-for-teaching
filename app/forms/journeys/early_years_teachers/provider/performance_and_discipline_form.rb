module Journeys
  module EarlyYearsTeachers
    module Provider
      class PerformanceAndDisciplineForm < Form
        attribute :performance_or_discipline, :boolean

        validates :performance_or_discipline,
          inclusion: {
            in: [true, false],
            message: i18n_error_message(:inclusion)
          }

        def save
          return false if invalid?

          answers.current_teacher.performance_or_discipline = performance_or_discipline
          answers.current_teacher.save!

          current_teacher_id = if performance_or_discipline
            answers.current_teacher_id
          else
            # If answered false reset the current teacher id so we can add
            # additional teachers
            nil
          end

          journey_session.answers.assign_attributes(
            teacher_details: answers.teachers.map(&:attributes),
            current_teacher_id: current_teacher_id
          )
          journey_session.save!
        end

        def completed?
          false
          # answers.current_teacher.performance_and_discipline_completed?
        end

        def teacher_name
          answers.current_teacher&.teacher_full_name || "this teacher"
        end

        def radio_options
          [
            Option.new(id: true, name: "Yes"),
            Option.new(id: false, name: "No")
          ]
        end

        private

        def load_current_value(attribute)
          if answers.current_teacher.present? && answers.current_teacher.attribute_names.include?(attribute.to_s)
            puts "loading attribute #{attribute}"
            v = answers.current_teacher.public_send(attribute)
            puts "value #{v.inspect}"
            v
          end
        end
      end
    end
  end
end

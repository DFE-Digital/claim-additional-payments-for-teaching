module Journeys
  module EarlyYearsTeachers
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :provider_email_address, :string, pii: false
        attribute :check_your_email_clicked, :boolean, pii: false
        attribute :nursery_details_confirmed, :boolean, pii: false
        attribute :nursery_details_updated, :boolean, pii: false

        attribute :nursery_name, :string, pii: true
        attribute :nursery_address_line_1, pii: true
        attribute :nursery_address_city, pii: true
        attribute :nursery_address_postcode, pii: true
        attribute :ofsted_urn, :string, pii: true
        attribute :provider_status, :string, pii: false
        attribute :nursery_type, :string, pii: false
        attribute :nursery_subtype, :string, pii: false

        attribute :employer_paye_reference, :string, pii: true

        attribute :organisation_email_address, :string, pii: true

        attribute :teacher_details, pii: true, default: []

        attribute(
          :teacher_details_form_completed,
          :boolean,
          pii: false,
          default: false
        )

        attribute :current_teacher_id, :string, pii: false

        attribute(
          :performance_and_discipline_completed,
          :boolean,
          pii: false,
          default: false
        )

        attribute :add_another_teacher, :boolean, pii: false

        # FIXME added for prototyping - delete this when we're persisting claims
        attribute(
          :check_your_answers_form_completed,
          :boolean,
          pii: false
        )

        class Teacher
          include ActiveModel::Model
          include ActiveModel::Attributes

          attribute :teacher_id
          attribute :teacher_full_name
          attribute :teacher_email_address
          attribute :teacher_mobile_phone_number
          attribute :teacher_national_insurance_number
          attribute :teacher_reference_number
          attribute :performance_or_discipline

          def initialize(params)
            @answers = params.delete(:answers)

            super
          end

          def save!
            if new_record?
              self.teacher_id = SecureRandom.uuid

              teachers = @answers.teachers << self
            else
              teachers = @answers.teachers.map do |t|
                if t.teacher_id == teacher_id
                  self
                else
                  t
                end
              end
            end

            @answers.send(:teachers=, teachers)
          end

          def destroy!
            teachers = @answers.teachers.map do |t|
              if t.teacher_id == teacher_id
                nil
              else
                t
              end
            end.compact

            @answers.send(:teachers=, teachers)
          end

          def performance_and_discipline_completed?
            !performance_or_discipline.nil?
          end

          def performance_and_discipline_incomplete?
            performance_or_discipline.nil?
          end

          def new_record?
            !@answers.teachers.map(&:teacher_id).compact_blank.include?(teacher_id)
          end
        end

        def teachers
          @teachers ||= teacher_details.map do |teacher_attrs|
            Teacher.new(**teacher_attrs.symbolize_keys, answers: self)
          end
        end

        def current_teacher
          @current_teacher ||= teachers.detect { |t| t.teacher_id == current_teacher_id }
        end

        def new_teacher
          Teacher.new(answers: self)
        end

        def edit_teacher_path(teacher, return_to_slug:)
          Rails.application.routes.url_helpers.claim_path(
            session.journey_class.routing_name,
            "provide-teacher-details",
            :change => return_to_slug,
            teacher_form.model_name.param_key => {
              teacher_id: teacher.teacher_id
            }
          )
        end

        def delete_teacher_path(teacher, return_to_slug:)
          Rails.application.routes.url_helpers.claim_path(
            session.journey_class.routing_name,
            "provide-teacher-details",
            :change => return_to_slug,
            teacher_form.model_name.param_key => {
              teacher_id: teacher.teacher_id,
              remove_teacher: true
            }
          )
        end

        private

        def teacher_form
          ProvideTeacherDetailsForm.new(
            journey_session: session,
            journey: session.journey_class,
            params: ActionController::Parameters.new,
            session: {}
          )
        end

        attr_writer :teachers
      end
    end
  end
end

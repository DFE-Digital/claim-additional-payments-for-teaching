module Journeys
  module AdditionalPaymentsForTeaching
    class QualificationDetailsForm < Form
      attribute :qualifications_details_check, :boolean

      validates :qualifications_details_check,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("qualifications_details_check") }
        }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          qualifications_details_check: qualifications_details_check
        )

        if qualifications_details_check
          # Teacher has confirmed the details in the dqt record are correct, update
          # the eligibility with these details
          journey_session.answers.assign_attributes(
            qualification: answers.early_career_payments_dqt_teacher_record&.route_into_teaching || answers.qualification,
            itt_academic_year: answers.early_career_payments_dqt_teacher_record&.itt_academic_year_for_claim || answers.itt_academic_year,
            eligible_degree_subject: answers.levelling_up_premium_payments_dqt_reacher_record&.eligible_degree_code? || answers.eligible_degree_subject,
            eligible_itt_subject: eligible_itt_subject_from_dqt || answers.eligible_itt_subject
          )
        else
          # Teacher has said the details don't match what they expected so
          # nullify them
          journey_session.answers.assign_attributes(
            qualification: nil,
            itt_academic_year: nil,
            eligible_degree_subject: nil,
            eligible_itt_subject: nil
          )
        end
        journey_session.save!
      end

      def dqt_route_into_teaching
        dqt_teacher_record.route_into_teaching
      end

      def dqt_academic_date
        AcademicYear.for(dqt_teacher_record.academic_date)
      end

      def dqt_itt_subjects
        dqt_teacher_record.itt_subjects.map do |subject|
          format_subject(subject)
        end.join(", ")
      end

      def show_degree_subjects?
        [
          answers.early_career_payments_dqt_teacher_record,
          answers.levelling_up_premium_payments_dqt_reacher_record
        ].any? do |dqt_teacher_record|
          dqt_teacher_record.eligible_itt_subject_for_claim == :none_of_the_above
        end && dqt_teacher_record.degree_names.any?
      end

      def dqt_degree_subjects
        dqt_teacher_record.degree_names.map do |subject|
          format_subject(subject)
        end.join(", ")
      end

      private

      def eligible_itt_subject_from_dqt
        dqt_subjects = [
          answers.early_career_payments_dqt_teacher_record&.eligible_itt_subject_for_claim,
          answers.levelling_up_premium_payments_dqt_reacher_record&.eligible_itt_subject_for_claim
        ].compact

        return nil if dqt_subjects.empty?

        not_none_of_the_above = dqt_subjects.reject { |subject| subject == :none_of_the_above }

        if not_none_of_the_above.any?
          not_none_of_the_above.first
        else
          :none_of_the_above
        end
      end

      # Current claim used to delegate missing methods to ecp eligibility by
      # default so we'll assume that's the "main" dqt record
      def dqt_teacher_record
        answers.early_career_payments_dqt_teacher_record
      end

      # Often the DQT record will represent subject names in all lowercase
      def format_subject(string)
        (string.downcase == string) ? string.titleize : string
      end
    end
  end
end

module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleIttSubjectForm < Form
      include Claims::IttSubjectHelper

      attribute :eligible_itt_subject, :string

      validates :eligible_itt_subject,
        inclusion: {
          in: :available_options,
          message: i18n_error_message(:inclusion)
        },
        unless: :boolean_answer?

      validates :eligible_itt_subject,
        inclusion: {
          in: :available_options,
          message: ->(object, _data) {
            "Select yes if you did your #{qualification_to_substring(object.answers.qualification.to_sym)} in #{object.available_subjects.first}"
          }
        },
        if: :boolean_answer?

      def self.qualification_to_substring(qualification_symbol)
        {
          undergraduate_itt: "undergraduate initial teacher training (ITT)",
          postgraduate_itt: "postgraduate initial teacher training (ITT)",
          assessment_only: "assessment",
          overseas_recognition: "teaching qualification"
        }[qualification_symbol]
      end

      def available_subjects
        @available_subjects ||= subject_symbols.map(&:to_s)
      end

      def available_options
        available_subjects + ["none_of_the_above"]
      end

      def show_hint_text?
        answers.nqt_in_academic_year_after_itt &&
          available_subjects.many?
      end

      def chemistry_or_physics_available?
        available_subjects.include?("chemistry") ||
          available_subjects.include?("physics")
      end

      def subject_symbols
        return [] if answers.itt_academic_year&.none?

        if answers.nqt_in_academic_year_after_itt
          EligibilityChecker.new(journey_session: journey_session)
            .potentially_still_eligible.map do |policy|
              policy.current_and_future_subject_symbols(
                claim_year: answers.policy_year,
                itt_year: answers.itt_academic_year
              )
            end.flatten.uniq
        elsif answers.policy_year.in?(Policies::TargetedRetentionIncentivePayments::POLICY_RANGE)
          # they get the standard, unchanging Targeted Retention Incentive subject set because they won't have qualified in time for ECP by 2022/2023
          # and they won't have given an ITT year
          Policies::TargetedRetentionIncentivePayments.fixed_subject_symbols
        else
          []
        end
      end

      def save
        return false unless valid?

        if eligible_itt_subject_changed? && !journey_session.answers.qualifications_details_check
          journey_session.answers.assign_attributes(
            teaching_subject_now: nil,
            eligible_degree_subject: nil
          )
        end

        journey_session.answers.assign_attributes(
          eligible_itt_subject:
        )

        journey_session.save!
      end

      private

      def eligible_itt_subject_changed?
        journey_session.answers.eligible_itt_subject != eligible_itt_subject
      end

      def boolean_answer?
        !available_subjects.many?
      end
    end
  end
end

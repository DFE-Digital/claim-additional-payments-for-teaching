module Journeys
  module TargetedRetentionIncentivePayments
    class EligibleIttSubjectForm < Form
      attribute :eligible_itt_subject, :string

      validates :eligible_itt_subject, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        if eligible_itt_subject_changed? && !answers.qualifications_details_check
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

      def radio_options
        subject_symbols.map do |subject_symbol|
          Option.new(
            id: subject_symbol.to_s,
            name: t("options.#{subject_symbol}")
          )
        end.push(none_of_the_above)
      end

      def none_of_the_above
       Option.new(
         id: "none_of_the_above",
         name: t("options.none_of_the_above"),
       )
      end

      def question_locale_key
        if answers.trainee_teacher?
          [:question, :trainee]
        else
          [:question, :qualified, answers.qualification]
        end
      end

      private

      def subject_symbols
        Policies::TargetedRetentionIncentivePayments
          .current_and_future_subject_symbols(
            itt_year: answers.itt_academic_year,
            claim_year: journey.configuration.current_academic_year
          )
      end

      def eligible_itt_subject_changed?
        answers.eligible_itt_subject != eligible_itt_subject
      end
    end
  end
end


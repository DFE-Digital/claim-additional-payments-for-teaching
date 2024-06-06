module Journeys
  module AdditionalPaymentsForTeaching
    class QualificationDetailsForm < Form
      attribute :qualifications_details_check, :boolean

      validates :qualifications_details_check,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("qualifications_details_check") }
        }

      def initialize(...)
        super

        # FIXME RL: This is a hack to avoid having to change too much in one
        # commit (we're already changing a lot). The DQT record checks these
        # attributes we're setting to determine it's answers, however we've not
        # migrated the forms that set these attributes to write to the journey
        # session ansswers, so we need to set these values from the elgiibility
        # here.
        journey_session.answers.itt_academic_year = claim.eligibility.itt_academic_year
        journey_session.answers.qualification = claim.eligibility.qualification
        journey_session.answers.eligible_degree_subject = claim.for_policy(Policies::LevellingUpPremiumPayments).eligibility.eligible_degree_subject
      end

      def save
        return false unless valid?

        claim.assign_attributes(
          qualifications_details_check: qualifications_details_check
        )

        if qualifications_details_check
          # Teacher has confirmed the details in the dqt record are correct, update
          # the eligibility with these details
          claim.claims.each { |c| set_qualifications_from_dqt_record(c.eligibility) }
        else
          # Teacher has said the details don't match what they expected so
          # nullify them
          claim.claims.each { |c| set_nil_qualifications(c.eligibility) }
        end

        claim.save!
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

      # Current claim delegates missing methods to ecp eligibility by default
      # so we'll assume that's the "main" dqt record
      def dqt_teacher_record
        answers.early_career_payments_dqt_teacher_record
      end

      # Often the DQT record will represent subject names in all lowercase
      def format_subject(string)
        (string.downcase == string) ? string.titleize : string
      end

      def set_qualifications_from_dqt_record(eligibility)
        case eligibility
        when Policies::EarlyCareerPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: itt_academic_year(answers.early_career_payments_dqt_teacher_record, eligibility),
            eligible_itt_subject: eligible_itt_subject(answers.early_career_payments_dqt_teacher_record, eligibility),
            qualification: qualification(answers.early_career_payments_dqt_teacher_record, eligibility)
          )
        when Policies::LevellingUpPremiumPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: itt_academic_year(answers.levelling_up_premium_payments_dqt_reacher_record, eligibility),
            eligible_itt_subject: eligible_itt_subject(answers.levelling_up_premium_payments_dqt_reacher_record, eligibility),
            qualification: qualification(answers.levelling_up_premium_payments_dqt_reacher_record, eligibility),
            eligible_degree_subject: eligible_degree_subject(answers.levelling_up_premium_payments_dqt_reacher_record, eligibility)
          )
        else
          fail "Unknown eligibility type #{eligibility.class}"
        end
      end

      def set_nil_qualifications(eligibility)
        case eligibility
        when Policies::EarlyCareerPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: nil,
            eligible_itt_subject: nil,
            qualification: nil
          )
        when Policies::LevellingUpPremiumPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: nil,
            eligible_itt_subject: nil,
            qualification: nil,
            eligible_degree_subject: nil
          )
        else
          fail "Unknown eligibility type #{eligibility.class}"
        end
      end

      def itt_academic_year(dqt_teacher_record, eligibility)
        dqt_teacher_record&.itt_academic_year_for_claim || eligibility.itt_academic_year
      end

      def eligible_itt_subject(dqt_teacher_record, eligibility)
        dqt_teacher_record&.eligible_itt_subject_for_claim || eligibility.eligible_itt_subject
      end

      def qualification(dqt_teacher_record, eligibility)
        dqt_teacher_record&.route_into_teaching || eligibility.qualification
      end

      def eligible_degree_subject(dqt_teacher_record, eligibility)
        dqt_teacher_record&.eligible_degree_code? || eligibility.eligible_degree_subject
      end
    end
  end
end

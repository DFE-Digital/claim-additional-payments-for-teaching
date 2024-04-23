module Journeys
  module AdditionalPaymentsForTeaching
    class QualificationDetailsForm < Form
      attribute :qualifications_details_check, :boolean

      validates :qualifications_details_check,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("qualifications_details_check") }
        }

      def initialize(claim:, journey:, params:)
        super

        self.qualifications_details_check = permitted_params.fetch(
          :qualifications_details_check,
          claim.qualifications_details_check
        )
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
        claim.dqt_teacher_record.route_into_teaching
      end

      def dqt_academic_date
        AcademicYear.for(claim.dqt_teacher_record.academic_date)
      end

      def dqt_itt_subjects
        claim.dqt_teacher_record.itt_subjects.map do |subject|
          format_subject(subject)
        end.join(", ")
      end

      def show_degree_subjects?
        claim.claims.any? do |c|
          c.dqt_teacher_record.eligible_itt_subject_for_claim == :none_of_the_above
        end && claim.dqt_teacher_record.degree_names.any?
      end

      def dqt_degree_subjects
        claim.dqt_teacher_record.degree_names.map do |subject|
          format_subject(subject)
        end.join(", ")
      end

      private

      # Often the DQT record will represent subject names in all lowercase
      def format_subject(string)
        (string.downcase == string) ? string.titleize : string
      end

      def set_qualifications_from_dqt_record(eligibility)
        dqt_record = eligibility.claim.dqt_teacher_record

        case eligibility
        when Policies::EarlyCareerPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: itt_academic_year(dqt_record, eligibility),
            eligible_itt_subject: eligible_itt_subject(dqt_record, eligibility),
            qualification: qualification(dqt_record, eligibility)
          )
        when Policies::LevellingUpPremiumPayments::Eligibility
          eligibility.assign_attributes(
            itt_academic_year: itt_academic_year(dqt_record, eligibility),
            eligible_itt_subject: eligible_itt_subject(dqt_record, eligibility),
            qualification: qualification(dqt_record, eligibility),
            eligible_degree_subject: eligible_degree_subject(dqt_record, eligibility)
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

require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::AnswersPresenter, type: :model do
  describe "#eligibility_answers" do
    let(:school) { create(:school) }

    subject(:answers) do
      described_class.new(journey_session).eligibility_answers
    end

    before do
      create(:journey_configuration, :targeted_retention_incentive_payments)
    end

    context "when not a supply teacher and no DQT data" do
      let(:journey_session) do
        create(
          :targeted_retention_incentive_payments_session,
          answers: {
            current_school_id: school.id,
            nqt_in_academic_year_after_itt: true,
            employed_as_supply_teacher: false,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            qualification: :postgraduate_itt,
            itt_academic_year: Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year,
            eligible_itt_subject: eligible_itt_subject,
            teaching_subject_now: true
          }
        )
      end

      context "when has an eligible_itt_subject" do
        let(:eligible_itt_subject) { :physics }

        it do
          is_expected.to eq [
            ["Which school do you teach at?", school.name, "current-school"],
            ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
            ["Are you currently employed as a supply teacher?", "No", "supply-teacher"],
            ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?", "No", "poor-performance"],
            ["Are you currently subject to disciplinary action?", "No", "poor-performance"],
            ["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"],
            ["In which academic year did you start your postgraduate initial teacher training (ITT)?", Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year.to_s(:long), "itt-year"],
            ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Physics", "eligible-itt-subject"],
            ["Do you spend at least half of your contracted hours teaching eligible subjects?", "Yes", "teaching-subject-now"]
          ]
        end
      end

      context "when eligible_itt_subject of none_of_the_above" do
        let(:eligible_itt_subject) { :none_of_the_above }

        it do
          is_expected.to eq [
            ["Which school do you teach at?", school.name, "current-school"],
            ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
            ["Are you currently employed as a supply teacher?", "No", "supply-teacher"],
            ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?", "No", "poor-performance"],
            ["Are you currently subject to disciplinary action?", "No", "poor-performance"],
            ["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"],
            ["In which academic year did you start your postgraduate initial teacher training (ITT)?", Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year.to_s(:long), "itt-year"],
            ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "None of the above", "eligible-itt-subject"],
            ["Do you have a degree in an eligible subject?", "No", "eligible-degree-subject"],
            ["Do you spend at least half of your contracted hours teaching eligible subjects?", "Yes", "teaching-subject-now"]
          ]
        end
      end
    end

    context "when a supply teacher and no DQT data" do
      let(:journey_session) do
        create(
          :targeted_retention_incentive_payments_session,
          answers: {
            current_school_id: school.id,
            nqt_in_academic_year_after_itt: true,
            employed_as_supply_teacher: true,
            has_entire_term_contract: true,
            employed_directly: true,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            qualification: :postgraduate_itt,
            itt_academic_year: Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year,
            eligible_itt_subject: :physics,
            teaching_subject_now: true
          }
        )
      end

      it do
        is_expected.to eq [
          ["Which school do you teach at?", school.name, "current-school"],
          ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
          ["Are you currently employed as a supply teacher?", "Yes", "supply-teacher"],
          ["Do you have a contract to teach at the same school for an entire term or longer?", "Yes", "entire-term-contract"],
          ["Are you employed directly by your school?", "Yes, I'm employed by my school", "employed-directly"],
          ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?", "No", "poor-performance"],
          ["Are you currently subject to disciplinary action?", "No", "poor-performance"],
          ["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"],
          ["In which academic year did you start your postgraduate initial teacher training (ITT)?", Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year.to_s(:long), "itt-year"],
          ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Physics", "eligible-itt-subject"],
          ["Do you spend at least half of your contracted hours teaching eligible subjects?", "Yes", "teaching-subject-now"]
        ]
      end
    end

    context "DQT qualifications checked" do
      let(:journey_session) do
        create(
          :targeted_retention_incentive_payments_session,
          answers: {
            details_check: true,
            dqt_teacher_status: {
              qualified_teacher_status: {
                qts_date: "2024-01-01"
              },
              initial_teacher_training: {
                subject1: "mathematics",
                subject1_code: "G100",
                qualification: "BA (Hons)"
              }
            },
            current_school_id: school.id,
            nqt_in_academic_year_after_itt: true,
            employed_as_supply_teacher: false,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            qualifications_details_check: true,
            qualification: :postgraduate_itt,
            itt_academic_year: Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year,
            eligible_itt_subject: :mathematics,
            teaching_subject_now: true
          }
        )
      end

      it do
        is_expected.to eq [
          ["Which school do you teach at?", school.name, "current-school"],
          ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
          ["Are you currently employed as a supply teacher?", "No", "supply-teacher"],
          ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?", "No", "poor-performance"],
          ["Are you currently subject to disciplinary action?", "No", "poor-performance"],
          ["Do you spend at least half of your contracted hours teaching eligible subjects?", "Yes", "teaching-subject-now"]
        ]
      end
    end
  end
end

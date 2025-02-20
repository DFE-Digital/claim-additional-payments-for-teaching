require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::AnswersPresenter do
  let(:policy) { Policies::EarlyCareerPayments }
  it_behaves_like "journey answers presenter"

  describe "#eligibility_answers" do
    let(:policy_year) { AcademicYear.new(2022) }
    let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: policy_year) }
    let(:qualifications_details_check) { false }
    let(:qualification) { "postgraduate_itt" }

    let(:journey_session) do
      create(:additional_payments_session, answers: answers)
    end

    subject { described_class.new(journey_session).eligibility_answers }

    context "ECP" do
      before { journey_session.answers.nqt_in_academic_year_after_itt = true }

      context "long-term directly employed supply teacher" do
        let(:answers) do
          build(
            :additional_payments_answers,
            :ecp_eligible,
            :long_term_directly_employed_supply_teacher
          )
        end

        it {
          is_expected.to include(
            ["Are you currently employed as a supply teacher?", "Yes", "supply-teacher"],
            ["Do you have a contract to teach at the same school for an entire term or longer?", "Yes", "entire-term-contract"],
            ["Are you employed directly by your school?", "Yes", "employed-directly"]
          )
        }

        specify {
          expect(questions(subject)).to match_array([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Have you completed your induction as an early-career teacher?",
            "Are you currently employed as a supply teacher?",
            "Do you have a contract to teach at the same school for an entire term or longer?",
            "Are you employed directly by your school?",
            "Are you subject to any formal performance measures as a result of continuous poor teaching standards?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Did you do your postgraduate initial teacher training (ITT) in mathematics?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end

      context "non-supply teacher" do
        let(:answers) { build(:additional_payments_answers, :ecp_eligible) }

        it { is_expected.to include(["Are you currently employed as a supply teacher?", "No", "supply-teacher"]) }

        it {
          is_expected.not_to include(
            ["Do you have a contract to teach at the same school for an entire term or longer?", a_string_matching(/(Yes|No)/), "entire-term-contract"],
            ["Are you employed directly by your school?", a_string_matching(/(Yes|No)/), "employed-directly"]
          )
        }

        specify {
          expect(questions(subject)).to match_array([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Have you completed your induction as an early-career teacher?",
            "Are you currently employed as a supply teacher?",
            "Are you subject to any formal performance measures as a result of continuous poor teaching standards?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Did you do your postgraduate initial teacher training (ITT) in mathematics?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end

      context "single subject option" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
        let(:answers) do
          build(
            :additional_payments_answers,
            :ecp_eligible,
            itt_academic_year: itt_year
          )
        end

        it { is_expected.to include(["Did you do your postgraduate initial teacher training (ITT) in mathematics?", "Yes", "eligible-itt-subject"]) }
      end

      context "multiple subject options" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }
        let(:answers) do
          build(
            :additional_payments_answers,
            :ecp_eligible,
            itt_academic_year: itt_year
          )
        end

        it { is_expected.to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
      end

      context "qualifications retrieved from DQT" do
        let(:qualifications_details_check) { true }
        let(:early_career_payments_dqt_teacher_record) do
          double(
            itt_academic_year_for_claim:,
            eligible_itt_subject_for_claim:,
            route_into_teaching:
          )
        end
        let(:itt_academic_year_for_claim) { AcademicYear.for(Date.new(1981, 1, 1)) }
        let(:eligible_itt_subject_for_claim) { :mathematics }
        let(:route_into_teaching) { :postgraduate_itt }

        let(:answers) do
          build(
            :additional_payments_answers,
            :ecp_eligible,
            qualifications_details_check: qualifications_details_check,
            qualification: qualification
          )
        end

        before do
          allow_any_instance_of(
            Journeys::AdditionalPaymentsForTeaching::SessionAnswers
          ).to(
            receive(:early_career_payments_dqt_teacher_record).and_return(early_career_payments_dqt_teacher_record)
          )
        end

        context "all data is present" do
          it { is_expected.not_to include(["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"]) }
          it { is_expected.not_to include(["In which academic year did you start your postgraduate initial teacher training (ITT)?", "2019 - 2020", "itt-year"]) }
          it { is_expected.not_to include(["Did you do your postgraduate initial teacher training (ITT) in mathematics?", "Yes", "eligible-itt-subject"]) }
          it { is_expected.not_to include(["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"]) }
        end

        context "qualification was missing" do
          let(:route_into_teaching) { nil }
          it { is_expected.to include(["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"]) }
        end

        context "subject was missing" do
          let(:eligible_itt_subject_for_claim) { nil }
          it { is_expected.to include(["Did you do your postgraduate initial teacher training (ITT) in mathematics?", "Yes", "eligible-itt-subject"]) }
        end

        context "academic year was missing" do
          let(:itt_academic_year_for_claim) { nil }
          it { is_expected.to include(["In which academic year did you start your postgraduate initial teacher training (ITT)?", "2019 - 2020", "itt-year"]) }
        end
      end
    end

    context "Targeted Retention Incentive" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      context "entire output" do
        let(:expected_itt_year) { AcademicYear.new(answers.itt_academic_year) }
        let(:answers) do
          build(
            :additional_payments_answers,
            :targeted_retention_incentive_eligible,
            :targeted_retention_incentive_ineligible_itt_subject,
            :relevant_degree,
            :long_term_directly_employed_supply_teacher,
            selected_policy: "TargetedRetentionIncentivePayments"
          )
        end

        before do
          journey_session.answers.assign_attributes(nqt_in_academic_year_after_itt: true)
        end

        it {
          is_expected.to match_array(
            [
              ["Which school do you teach at?", answers.current_school.name, "current-school"],
              ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
              ["Have you completed your induction as an early-career teacher?", "No", "induction-completed"],
              ["Are you currently employed as a supply teacher?", "Yes", "supply-teacher"],
              ["Do you have a contract to teach at the same school for an entire term or longer?", "Yes", "entire-term-contract"],
              ["Are you employed directly by your school?", "Yes", "employed-directly"],
              ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?", "No", "poor-performance"],
              ["Are you currently subject to disciplinary action?", "No", "poor-performance"],
              ["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"],
              ["In which academic year did you start your postgraduate initial teacher training (ITT)?", "#{expected_itt_year.start_year} - #{expected_itt_year.end_year}", "itt-year"],
              ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Languages", "eligible-itt-subject"],
              ["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"],
              ["Do you spend at least half of your contracted hours teaching eligible subjects?", "Yes", "teaching-subject-now"]
            ]
          )
        }
      end

      context "qualifications retrieved from DQT" do
        let(:qualifications_details_check) { true }
        let(:early_career_payments_dqt_teacher_record) do
          double(
            itt_academic_year_for_claim:,
            eligible_itt_subject_for_claim:,
            route_into_teaching:
          )
        end
        let(:targeted_retention_incentive_payments_dqt_reacher_record) do
          double(
            itt_academic_year_for_claim:,
            eligible_itt_subject_for_claim:,
            route_into_teaching:,
            eligible_degree_code?: eligible_degree_code
          )
        end
        let(:itt_academic_year_for_claim) { AcademicYear.for(Date.new(1981, 1, 1)) }
        let(:eligible_itt_subject_for_claim) { :mathematics }
        let(:route_into_teaching) { :postgraduate_itt }
        let(:eligible_degree_code) { true }

        let(:answers) do
          build(
            :additional_payments_answers,
            :targeted_retention_incentive_eligible,
            :relevant_degree,
            qualifications_details_check: qualifications_details_check,
            selected_policy: "TargetedRetentionIncentivePayments"
          )
        end

        before do
          allow_any_instance_of(
            Journeys::AdditionalPaymentsForTeaching::SessionAnswers
          ).to(
            receive(:early_career_payments_dqt_teacher_record)
              .and_return(early_career_payments_dqt_teacher_record)
          )

          allow_any_instance_of(
            Journeys::AdditionalPaymentsForTeaching::SessionAnswers
          ).to(
            receive(:targeted_retention_incentive_payments_dqt_reacher_record)
              .and_return(targeted_retention_incentive_payments_dqt_reacher_record)
          )
        end

        context "all data is present" do
          it { is_expected.not_to include(["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"]) }
          it { is_expected.not_to include(["In which academic year did you start your postgraduate initial teacher training (ITT)?", "2021 - 2022", "itt-year"]) }
          it { is_expected.not_to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
          it { is_expected.not_to include(["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"]) }
        end

        context "qualification was missing" do
          let(:route_into_teaching) { nil }
          it { is_expected.to include(["Which route into teaching did you take?", "Postgraduate initial teacher training (ITT)", "qualification"]) }
        end

        context "subject was missing" do
          let(:eligible_itt_subject_for_claim) { nil }
          it { is_expected.to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
        end

        context "academic year was missing" do
          let(:itt_academic_year_for_claim) { nil }
          it { is_expected.to include(["In which academic year did you start your postgraduate initial teacher training (ITT)?", "2021 - 2022", "itt-year"]) }
        end

        context "degree code was missing" do
          let(:eligible_degree_code) { nil }
          it { is_expected.to include(["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"]) }
        end
      end

      context "eligible ITT" do
        let(:answers) do
          build(
            :additional_payments_answers,
            :targeted_retention_incentive_eligible,
            selected_policy: "TargetedRetentionIncentivePayments"
          )
        end

        it { is_expected.to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
        it { is_expected.not_to include(["Do you have a degree in an eligible subject?", a_string_matching(/(Yes|No)/), "eligible-degree-subject"]) }

        specify {
          expect(questions(subject)).to eq([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Have you completed your induction as an early-career teacher?",
            "Are you currently employed as a supply teacher?",
            "Are you subject to any formal performance measures as a result of continuous poor teaching standards?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Which subject did you do your postgraduate initial teacher training (ITT) in?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end

      context "ineligible ITT" do
        let(:answers) do
          build(
            :additional_payments_answers,
            :targeted_retention_incentive_eligible,
            :targeted_retention_incentive_ineligible_itt_subject,
            :relevant_degree,
            selected_policy: "TargetedRetentionIncentivePayments"
          )
        end

        it {
          is_expected.to include(
            ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Languages", "eligible-itt-subject"],
            ["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"]
          )
        }

        specify {
          expect(questions(subject)).to match_array([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Have you completed your induction as an early-career teacher?",
            "Are you currently employed as a supply teacher?",
            "Are you subject to any formal performance measures as a result of continuous poor teaching standards?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Which subject did you do your postgraduate initial teacher training (ITT) in?",
            "Do you have a degree in an eligible subject?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end
    end
  end

  def questions(questions_and_answers_array)
    questions_and_answers_array.collect(&:first)
  end
end

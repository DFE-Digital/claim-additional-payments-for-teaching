require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAnswersPresenter do
  describe "#answers" do
    let(:policy_year) { AcademicYear.new(2022) }
    let(:policy) { EarlyCareerPayments }
    let(:claim) { build(:claim, policy: policy, academic_year: policy_year, eligibility: eligibility) }
    let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

    subject { described_class.new(claim.eligibility).answers }

    context "ECP" do
      context "long-term directly employed supply teacher" do
        let(:eligibility) { build(:early_career_payments_eligibility, :eligible, :long_term_directly_employed_supply_teacher) }

        it {
          is_expected.to include(
            ["Are you currently employed as a supply teacher?", "Yes", "supply-teacher"],
            ["Do you have a contract to teach at the same school for an entire term or longer?", "Yes", "entire-term-contract"],
            ["Are you employed directly by your school?", "Yes", "employed-directly"]
          )
        }

        specify {
          expect(questions(subject)).to eq([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Are you currently employed as a supply teacher?",
            "Do you have a contract to teach at the same school for an entire term or longer?",
            "Are you employed directly by your school?",
            "Have any performance measures been started against you?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Did you do your postgraduate initial teacher training (ITT) in mathematics?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end

      context "non-supply teacher" do
        let(:eligibility) { build(:early_career_payments_eligibility, :eligible, :not_a_supply_teacher) }

        it { is_expected.to include(["Are you currently employed as a supply teacher?", "No", "supply-teacher"]) }

        it {
          is_expected.not_to include(
            ["Do you have a contract to teach at the same school for an entire term or longer?", a_string_matching(/(Yes|No)/), "entire-term-contract"],
            ["Are you employed directly by your school?", a_string_matching(/(Yes|No)/), "employed-directly"]
          )
        }

        specify {
          expect(questions(subject)).to eq([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Are you currently employed as a supply teacher?",
            "Have any performance measures been started against you?",
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
        let(:eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year) }

        it { is_expected.to include(["Did you do your postgraduate initial teacher training (ITT) in mathematics?", "Yes", "eligible-itt-subject"]) }
      end

      context "multiple subject options" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }
        let(:eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year) }

        it { is_expected.to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
      end
    end

    context "LUP" do
      let(:policy) { LevellingUpPremiumPayments }

      context "entire output" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :long_term_directly_employed_supply_teacher, :ineligible_itt_subject, :relevant_degree) }
        let(:expected_itt_year) { AcademicYear.new(eligibility.itt_academic_year) }

        it {
          is_expected.to eq(
            [
              ["Which school do you teach at?", eligibility.current_school.name, "current-school"],
              ["Are you currently teaching as a qualified teacher?", "Yes", "nqt-in-academic-year-after-itt"],
              ["Are you currently employed as a supply teacher?", "Yes", "supply-teacher"],
              ["Do you have a contract to teach at the same school for an entire term or longer?", "Yes", "entire-term-contract"],
              ["Are you employed directly by your school?", "Yes", "employed-directly"],
              ["Have any performance measures been started against you?", "No", "poor-performance"],
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

      context "eligible ITT" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

        it { is_expected.to include(["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Mathematics", "eligible-itt-subject"]) }
        it { is_expected.not_to include(["Do you have a degree in an eligible subject?", a_string_matching(/(Yes|No)/), "eligible-degree-subject"]) }

        specify {
          expect(questions(subject)).to eq([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Are you currently employed as a supply teacher?",
            "Have any performance measures been started against you?",
            "Are you currently subject to disciplinary action?",
            "Which route into teaching did you take?",
            "In which academic year did you start your postgraduate initial teacher training (ITT)?",
            "Which subject did you do your postgraduate initial teacher training (ITT) in?",
            "Do you spend at least half of your contracted hours teaching eligible subjects?"
          ])
        }
      end

      context "ineligible ITT" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, :ineligible_itt_subject, :relevant_degree) }

        it {
          is_expected.to include(
            ["Which subject did you do your postgraduate initial teacher training (ITT) in?", "Languages", "eligible-itt-subject"],
            ["Do you have a degree in an eligible subject?", "Yes", "eligible-degree-subject"]
          )
        }

        specify {
          expect(questions(subject)).to eq([
            "Which school do you teach at?",
            "Are you currently teaching as a qualified teacher?",
            "Are you currently employed as a supply teacher?",
            "Have any performance measures been started against you?",
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

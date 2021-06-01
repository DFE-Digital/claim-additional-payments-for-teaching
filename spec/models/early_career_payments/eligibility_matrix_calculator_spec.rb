require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityMatrixCalculator, type: :model do
  let(:eligibility_attributes) do
    {
      nqt_in_academic_year_after_itt: true,
      current_school: schools(:penistone_grammar_school),
      employed_as_supply_teacher: false,
      subject_to_formal_performance_action: false,
      subject_to_disciplinary_action: false,
      pgitt_or_ugitt_course: :postgraduate,
      eligible_itt_subject: subject,
      teaching_subject_now: true,
      itt_academic_year: itt_academic_year
    }
  end
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, eligibility: build(:early_career_payments_eligibility, eligibility_attributes)) }

  subject(:matrix_calculator) { described_class.new(eligibility) }

  describe "#eligible_later?" do
    describe "teaching mathematics" do
      let(:subject) { :mathematics }

      context "when '2018_2019' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2018_2019" }

        it "returns false" do
          expect(matrix_calculator.eligible_later?).to be false
        end
      end

      context "when '2019_2020' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2019_2020" }

        it "returns true" do
          expect(matrix_calculator.eligible_later?).to be true
        end
      end

      context "when '2020_2021' was academic year of (starting postgraduate / completed undergraduate) ITT" do
        let(:itt_academic_year) { "2020_2021" }

        it "returns true" do
          expect(matrix_calculator.eligible_later?).to be true
        end
      end
    end

    describe "teaching chemistry" do
      let(:subject) { :chemistry }

      context "when '2020_2021' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2020_2021" }

        it "returns true" do
          expect(matrix_calculator.eligible_later?).to be true
        end
      end
    end

    describe "teaching physics" do
      let(:subject) { :physics }

      context "when '2020_2021' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2020_2021" }

        it "returns true" do
          expect(matrix_calculator.eligible_later?).to be true
        end
      end
    end

    describe "teaching foreign languages" do
      let(:subject) { :foreign_languages }

      context "when '2020_2021' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2020_2021" }

        it "returns true" do
          expect(matrix_calculator.eligible_later?).to be true
        end
      end
    end

    describe "teaching none of the qualifying subjects" do
      let(:subject) { :none_of_the_above }

      context "when '2020_2021' was academic year of (start postgraduate / complete undergraduate) ITT" do
        let(:itt_academic_year) { "2020_2021" }

        it "returns false" do
          expect(matrix_calculator.eligible_later?).to be false
        end
      end
    end
  end
end

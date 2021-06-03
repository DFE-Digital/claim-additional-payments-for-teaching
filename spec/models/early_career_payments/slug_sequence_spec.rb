require "rails_helper"

RSpec.describe EarlyCareerPayments::SlugSequence do
  let(:eligibility) { build(:early_career_payments_eligibility) }
  let(:claim) { build(:claim, eligibility: eligibility) }

  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(claim) }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")

      claim.eligibility.nqt_in_academic_year_after_itt = false
      expect(claim.eligibility).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes the 'entire-term-contract' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract")
    end

    it "excludes the 'employed-directly' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("employed-directly")
    end

    context "when assessing if to include 'eligibility_confirmed' slug" do
      let(:eligibility) { build(:early_career_payments_eligibility, :mathematics_and_itt_year_2018) }

      it "excludes the 'eligibility_confirmed' slug when the claim is ineligible" do
        claim.eligibility.eligible_itt_subject = :foreign_languages

        expect(slug_sequence.slugs).not_to include("eligibility_confirmed")
      end

      it "includes the 'eligibility_confirmed' slug when claim is eligible" do
        expect(slug_sequence.slugs).to include("eligibility_confirmed")
      end
    end

    context "when the answer to 'paying off student loan' is 'No'" do
      it "excludes 'student-loan-country', 'student-loan-how-many-courses', 'student-loan-start-date', 'masters-loan' and 'doctoral-loan'" do
        claim.has_student_loan = false

        expected_slugs = %w[
          nqt-in-academic-year-after-itt
          current-school
          supply-teacher
          formal-performance-action
          disciplinary-action
          postgraduate-itt-or-undergraduate-itt-course
          eligible-itt-subject
          teaching-subject-now
          itt_year
          check-your-answers-part-one
          how_we_will_use_information_provided
          personal-details
          address
          email-address
          email-verification
          bank-details
          gender
          teacher-reference-number
          student-loan
          check-your-answers
        ]

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end

    context "when the answer to 'student loan - home address ' is 'Scotland' OR 'Northen Ireland'" do
      let(:expected_slugs) do
        %w[
          nqt-in-academic-year-after-itt
          current-school
          supply-teacher
          formal-performance-action
          disciplinary-action
          postgraduate-itt-or-undergraduate-itt-course
          eligible-itt-subject
          teaching-subject-now
          itt_year
          check-your-answers-part-one
          how_we_will_use_information_provided
          personal-details
          address
          email-address
          email-verification
          bank-details
          gender
          teacher-reference-number
          student-loan
          student-loan-country
          masters-loan
          doctoral-loan
          check-your-answers
        ]
      end

      it "excludes 'student-loan-how-many-courses', 'student-loan-start-date' - Northern Ireland" do
        claim.student_loan_country = StudentLoan::NORTHERN_IRELAND

        expect(slug_sequence.slugs).to eq expected_slugs
      end

      it "excludes 'student-loan-how-many-courses', 'student-loan-start-date' - Scotland" do
        claim.student_loan_country = StudentLoan::SCOTLAND

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end
  end
end

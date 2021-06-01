require "rails_helper"

RSpec.describe EarlyCareerPayments::SlugSequence do
  let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }
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

    context "when assessing if to include 'eligibility-confirmed' slug" do
      let(:eligibility) { build(:early_career_payments_eligibility, :mathematics_and_itt_year_2018) }

      it "excludes the 'eligibility-confirmed' slug when the claim is ineligible" do
        claim.eligibility.eligible_itt_subject = :foreign_languages

        expect(slug_sequence.slugs).not_to include("eligibility-confirmed")
      end

      it "includes the 'eligibility-confirmed' slug when claim is eligible" do
        expect(slug_sequence.slugs).to include("eligibility-confirmed")
      end
    end

    context "when assessing if to include 'eligible-later' slug" do
      let(:eligibility) { build(:early_career_payments_eligibility, :chemistry_and_itt_year_2020) }

      it "excludes the 'eligible-later' slug when the claim is eligible" do
        claim.eligibility.eligible_itt_subject = :mathematics
        claim.eligibility.itt_academic_year = "2018_2019"

        expect(slug_sequence.slugs).not_to include("eligible-later")
      end

      it "includes the 'eligible-later' slug when claim is not eligible in the first claim year" do
        expect(slug_sequence.slugs).to include("eligible-later")
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
          itt-year
          check-your-answers-part-one
          eligible-later
          how-we-will-use-information-provided
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
          itt-year
          check-your-answers-part-one
          eligible-later
          how-we-will-use-information-provided
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

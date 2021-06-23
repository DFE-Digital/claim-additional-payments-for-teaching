require "rails_helper"

RSpec.describe EarlyCareerPayments::SlugSequence do
  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(claim) }

  let(:eligibility) { build(:early_career_payments_eligibility) }
  let(:claim) { build(:claim, eligibility: eligibility) }

  describe "The sequence as defined by #slugs" do
    it "excludes the 'ineligible' slug if the claim's eligibility is undetermined" do
      expect(slug_sequence.slugs).not_to include("ineligible")
    end

    it "excludes the 'entire-term-contract' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract")
    end

    it "excludes the 'employed-directly' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("employed-directly")
    end

    context "when claim is eligible" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "includes the 'eligibility_confirmed' slug" do
        expect(slug_sequence.slugs).to include("eligibility-confirmed")
      end
    end

    context "when claim is ineligible" do
      let(:eligibility) do
        build(
          :early_career_payments_eligibility,
          :eligible,
          eligible_itt_subject: :foreign_languages
        )
      end

      it "includes the 'ineligible' slug" do
        expect(slug_sequence.slugs).to include("ineligible")
      end

      it "excludes the 'eligibility-confirmed' slug" do
        expect(slug_sequence.slugs).not_to include("eligibility-confirmed")
      end
    end

    context "when claim is eligible later" do
      let(:eligibility) do
        build(
          :early_career_payments_eligibility,
          :eligible,
          eligible_itt_subject: itt_subject,
          itt_academic_year: itt_academic_year
        )
      end

      [
        {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020"},
        {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Physics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021"}
      ].each do |context|
        context "with ITT subject #{context[:itt_subject]}" do
          let(:itt_subject) { context[:itt_subject].gsub(/\s/, "_").downcase }

          context "with ITT academic year #{context[:itt_academic_year]}" do
            let(:itt_academic_year) { context[:itt_academic_year].gsub(/\s-\s/, "_") }

            it "excludes the 'eligibility-confirmed' slug" do
              expect(slug_sequence.slugs).not_to include("eligibility-confirmed")
            end

            it "includes the 'eligible-later' slug" do
              expect(slug_sequence.slugs).to include("eligible-later")
            end
          end
        end
      end
    end

    context "when claim is not eligible later" do
      let(:eligibility) do
        build(
          :early_career_payments_eligibility,
          :eligible,
          eligible_itt_subject: :mathematics,
          itt_academic_year: "2018_2019"
        )
      end

      it "excludes the 'eligibile-later' slug" do
        expect(slug_sequence.slugs).not_to include("eligibile-later")
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
          eligibility-confirmed
          how-we-will-use-information-provided
          personal-details
          address
          email-address
          email-verification
          provide-mobile-number
          bank-or-building-society
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
          eligibility-confirmed
          how-we-will-use-information-provided
          personal-details
          address
          email-address
          email-verification
          provide-mobile-number
          bank-or-building-society
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
